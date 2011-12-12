require 'test_helper'

class CommonStatesTest < Test::Unit::TestCase

  # a DD::Batch is a simple example
  def setup
    @object = Commoner.create!()
    assert @object.pending?
    assert @object.class.ancestors.include?(SuperState::CommonStates), "mate, it's not a CommonState thing"
  end

  test "a new record is pending?" do
    @object = Commoner.new
    assert @object.pending?
  end

  test "start_processing! - raises" do
    assert @object.pending?
    @object.expects(:valid?).returns(false)

    assert_raise(ActiveRecord::RecordInvalid) do
      @object.start_processing!
    end
    assert !@object.pending? # doesnt roll back
  end

  test "start_processing - returns false" do
    assert @object.pending?
    @object.expects(:valid?).returns(false)

    assert_equal false, @object.start_processing
    assert @object.pending? # rolls back
  end

  test "start_processing!" do
    assert @object.pending?

    assert @object.start_processing!

    before_and_after_reload @object do
      assert @object.processing?
    end
  end

  test "complete_processing!" do
    @object.start_processing!
    assert @object.processing?

    assert @object.complete_processing!

    before_and_after_reload @object do
      assert @object.completed?
    end
  end

  test "fail!" do
    @object.start_processing!
    assert @object.processing?

    assert @object.fail!

    before_and_after_reload @object do
      assert @object.failed?
    end
  end

  test "complete!" do
    assert @object.pending?

    assert @object.complete!

    before_and_after_reload @object do
      assert @object.completed?
    end
  end

  test "outstanding?" do
    assert @object.pending?
    assert @object.outstanding?

    @object.start_processing!
    assert @object.outstanding?

    @object.complete_processing!
    assert !@object.outstanding?
  end

end
