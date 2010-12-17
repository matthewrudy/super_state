module SuperState
  
  def self.included(klass)
    klass.class_eval do
      cattr_accessor :initial_super_state
      cattr_accessor :__super_states
      cattr_accessor :super_state_groups
      self.__super_states     = StateArray.new.all_states!
      self.super_state_groups = StateGroups.new
      
      extend ClassMethods
      include InstanceMethods
      
      # the initial_state only takes effect when we say record.valid?
      before_validation :set_initial_super_state, :on => :create
    end
  end
  
  # states should be stored as strings in all cases
  # (if it needs to be a sym, we should explicitly ask it to be)
  def self.canonicalise(value)
    if value
      if value.is_a?(Array)
        value.map{|v| self.canonicalise(v)}
      else
        value.to_s
      end
    end
  end
  
  # I want to know the states are the same
  class StateArray < Array
    
    def initialize(array=nil)
      super(SuperState.canonicalise(Array(array)))
    end
    
    def <<(value)
      super(SuperState.canonicalise(value))
    end
    
    def include?(value)
      super(SuperState.canonicalise(value))
    end
    
    def for_select
      self.map do |value|
        [value.humanize, value]
      end
    end
    
    def all_states!
      @all_states = true
      self
    end
    
    def all_states?
      @all_states
    end
    
  end
  
  class StateGroups < ActiveSupport::OrderedHash
    
    def []=(key, value)
      super(SuperState.canonicalise(key), SuperState.canonicalise(value))
    end
    
    def [](key)
      super(SuperState.canonicalise(key))
    end
    
    def keys
      StateArray.new(super)
    end
  
  end
  
  module InstanceMethods
    
    def current_super_state
      self[self.class.super_state_column] || SuperState.canonicalise(self.class.initial_super_state)
    end
    
    def set_initial_super_state
      set_super_state(self.class.initial_super_state)
    end
    
    def set_super_state(state_name, set_timestamps=true)
      self[self.class.super_state_column] = SuperState.canonicalise(state_name)
      
      if set_timestamps && self.respond_to?("#{state_name}_at=")
        self.send("#{state_name}_at=", Time.now)
      end
      
      self.current_super_state
    end
    
    def human_super_state
      self.current_super_state.humanize
    end
    
  end
  
  class BadState < ArgumentError ; end
  
  module ClassMethods
    
    def super_states_for_select(options={})
      rtn = []
      if options[:include_all]
        rtn << ["<All>", "all"]
      end
      if options[:include_groups]
        rtn += self.super_state_groups.keys.for_select
      end
      rtn += self.super_states.for_select
      
      rtn
    end
    
    def super_state(state_name, options={})
      if options[:initial] || self.initial_super_state.nil?
        self.initial_super_state = state_name
      end
      define_state_methods(state_name)
      self.__super_states << state_name
    end
    
    # a wrapper around state based scopes
    # to avoid malicious arguments;
    #   Loan.in_state(:disbursed) => Loan.disbursed
    #   Loan.in_state("active")   => Loan.active
    #   Loan.in_state("all")      => Loan.scoped
    #   Loan.in_state("")         => Loan.scoped
    #   Loan.in_state("something_evil") => Exception!
    def in_state(state_name)
      if state_array = self.super_states(state_name)
        self.scope_by_super_state(state_array)
      else
        raise BadState, "you are trying to scope by something other than a super state (or super state group)"
      end
    end
    
    # self.super_states        => ["first", "second", "third"]
    # self.super_states("")    => ["first", "second", "third"]
    # self.super_states("all") => ["first", "second", "third"]
    #
    # self.super_states("first") => ["first"]
    #
    # self.super_states("final") => ["second", "third"]
    #
    def super_states(state_name=nil)
      if state_name.blank? || state_name == "all"
        self.__super_states
      elsif self.__super_states.include?(state_name)
        StateArray.new(state_name)
      elsif self.super_state_groups.include?(state_name)
        self.super_state_groups[state_name]
      end
    end
    
    def scope_by_super_state(state_names)
      if state_names.is_a?(StateArray) && state_names.all_states?
        self.scoped
      else
        self.where(self.super_state_column => SuperState.canonicalise(state_names))
      end
    end
    
    # super_state_group(:active, [:approved, :requested, :disbursed])
    def super_state_group(group_name, group_states)
      define_state_methods(group_name, group_states)
      self.super_state_groups[group_name] = group_states
    end
    
    # state_transition :complete, :processing => :completed
    def state_transition(transition_name, state_hash, &transition_block)
      state_hash = state_hash.stringify_keys
      
      define_state_transition_method(transition_name,       state_hash, :save,  &transition_block)
      define_state_transition_method("#{transition_name}!", state_hash, :save!, &transition_block)
    end
    
    # internal methods
    
    def super_state_column
      :status
    end
    
    def define_state_methods(method_name, state_names=nil)
      state_names ||= method_name
      
      # Loan.completed # scope
      self.scope method_name, self.scope_by_super_state(state_names)
      
      # pretty much;
      #   def record.completed?
      #     record.status == "completed"
      #   end
      define_method("#{method_name}?") do
        StateArray.new(state_names).include?(self.current_super_state)
      end
    end
    
    def define_state_transition_method(method_name, state_hash, save_method, &transition_block)
      
      # pretty much;
      #   def record.complete!
      #     if record.pending?
      #       record.status = "completed"
      #       record.save!
      #     else
      #       raise SuperState::BadState
      #     end
      #   end
      define_method(method_name) do |*args|
        if to_state = state_hash[self.current_super_state]

          state_before = self.current_super_state
          self.set_super_state(to_state)

          if transition_block
            params = args.shift || {}
            self.instance_exec(params, &transition_block)
          end

          unless rtn = self.send(save_method)
            self.set_super_state(state_before, false) #roll it back on failure
          end
          rtn
        else
          raise SuperState::BadState, "#{method_name} can only be called from states #{state_hash.keys.inspect}"
        end
      end
      
    end
    
  end
end