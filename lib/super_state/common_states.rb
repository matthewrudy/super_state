module SuperState
  
  module CommonStates
  
    def self.included(klass)
      klass.class_eval do
        include SuperState
  
        super_state :pending, :initial => true
        super_state :processing
        super_state :completed
        super_state :failed
      
        super_state_group :outstanding, ["pending", "processing"]
      
        # first part of a two stage transition
        # eg.
        #   def process
        #     start_processing!
        #       do_the_stuff
        #     complete_processing!
        #   end
        #
        state_transition :start_processing, :pending => :processing
      
        # second part of a two stage transition
        state_transition :complete_processing, :processing => :completed
      
        # transition direct from pending to complete
        state_transition :complete, :pending => :completed
      
        # failed to process
        state_transition :fail, :processing => :failed
      
        # back to processing
        state_transition :restart, :failed => :processing
      end
    end
    
  end
  
end