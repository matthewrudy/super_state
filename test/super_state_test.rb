require 'test_helper'

class SuperStateTest < Test::Unit::TestCase
  
  test "status must be valid" do
    record = Something.new
    assert record.valid?
    
    record.save!
    assert record.start?
    
    record.status = "not_valid"
    assert !record.valid?
    assert_errors record, :status => "is not a valid super state"
    
    record.status = "start"
    assert record.valid?
  end
  
  test "abstract the tests" do
    puts "this has been abstracted from a live project"
    puts "as such the tests have not yet been abstracted"
    puts "give me some time to do this"
    flunk "abstract the tests"
  end
  
end
