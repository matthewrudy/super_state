require 'rubygems'
require 'test/unit'
require 'active_support/testing/declarative'
$: << File.expand_path(File.dirname(__FILE__)+"/../lib")

require 'super_state'

require 'active_record'
require 'mocha'

ActiveRecord::Base.establish_connection(
  :adapter => (RUBY_PLATFORM=="java" ? "jdbcsqlite3" : "sqlite3"),
  :database => ":memory:"
)

ActiveRecord::Schema.define(:version => 0) do
  create_table :somethings, :force => true do |t|
    t.string :status
  end
end

class Something < ActiveRecord::Base
  
  include SuperState
  
  super_state :start, :initial => true
  super_state :middle
  super_state :end
  
end

ActiveRecord::Schema.define(:version => 0) do
  create_table :commoners, :force => true do |t|
    t.string :status
  end
end

class Commoner < ActiveRecord::Base
  include SuperState::CommonStates
end

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
  
  def before_and_after_reload(record)
    yield
    record.reload
    yield
  end
  
  def assert_errors(record, fields)
    fields.each do |field, errors|
      assert_errors_on(errors, record, field)
    end
  end
  
  def assert_errors_on(errors, record, field)
    assert_equal Array(errors), Array(record.errors[field]), "unexpected errors on #{field.inspect}"
  end
  
  def assert_no_errors_on(record, field)
    assert_errors_on([], record, field)
  end
end