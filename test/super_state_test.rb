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
  
  test "ensure_super_state! - when the state has changed" do
    record = Something.create!
    assert record.start?
    
    # lets suppose a 2nd process has already kicked this off
    
    other = Something.find(record.id)
    other.kick_off!
    
    # but the original is still in the start state
    
    assert record.start?
    
    assert_raise_with_message SuperState::BadState, "the super state is not what we expected" do
      record.ensure_super_state!(:start) do
        record.kick_off!
      end
    end
  end
  
  test "ensure_super_state! - when the state is what we expect" do
    record = Something.create!
    assert record.start?
    
    record.ensure_super_state!(:start) do
      record.kick_off!
    end
    assert record.middle?
    assert record.reload.middle?
  end
  
  test "abstract the tests" do
    puts "this has been abstracted from a live project"
    puts "as such the tests have not yet been abstracted"
    puts "give me some time to do this"
    flunk "abstract the tests"
  end
  
end
