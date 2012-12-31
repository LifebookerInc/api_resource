require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Observing" do

  before(:all) do
    TestResource.reload_class_attributes
  end

  after(:all) do
    TestResource.observers = []
    TestResource.observer_instances.clear
    TestResource.reload_class_attributes
  end

  it "should notify observers on create" do
    tr = TestResource.new
    tr.expects(:notify_observers).with(:before_save).returns(true)
    tr.expects(:notify_observers).with(:before_create).returns(true)
    tr.expects(:create_without_observers).returns(true)
    tr.expects(:notify_observers).with(:after_create).returns(true)
    tr.expects(:notify_observers).with(:after_save).returns(true)
    tr.save
  end

  it "should notify observers on update" do
    tr = TestResource.new
    tr.stubs(:new?).returns(false)
    tr.expects(:notify_observers).with(:before_save).returns(true)
    tr.expects(:notify_observers).with(:before_update).returns(true)
    tr.expects(:update_without_observers).returns(true)
    tr.expects(:notify_observers).with(:after_update).returns(true)
    tr.expects(:notify_observers).with(:after_save).returns(true)
    tr.save
  end

  it "should notify observers on destroy" do
    tr = TestResource.new
    tr.stubs(:id).returns(1)
    tr.expects(:notify_observers).with(:before_destroy).returns(true)
    tr.expects(:destroy_without_observers).returns(true)
    tr.expects(:notify_observers).with(:after_destroy).returns(true)
    tr.destroy
  end

  it "should notify an observer for a given event" do
    class TestResourceObserver < ApiResource::Observer
      def before_save(elm)
        return true
      end
    end

    TestResourceObserver.any_instance.expects(:before_save).returns(true)
    # A bit of a pain to set these up ex post facto
    TestResource.observers = :test_resource_observer
    TestResource.instantiate_observers
    tr = TestResource.new
    tr.expects(:save_without_observers).returns(true)
    tr.save
  end

  it "should cancel the save if the observer returns false" do
    class TestResourceObserver < ApiResource::Observer
      def before_save(elm)
        return true
      end
    end

    TestResourceObserver.any_instance.expects(:before_save).returns(false)
    # A bit of a pain to set these up ex post facto
    TestResource.observers = :test_resource_observer
    TestResource.instantiate_observers
    tr = TestResource.new
    tr.expects(:save_without_observers).never
    tr.save
  end

  it "should run callbacks before observers" do
    klass = Class.new(TestResource)
    klass.class_eval <<-EOE, __FILE__, __LINE__ + 1
      before_save :abort_save

      def abort_save
        return false
      end
    EOE

    tr = klass.new
    tr.expects(:abort_save).returns(false)
    tr.expects(:notify_observers).never
    tr.expects(:save_without_callbacks).never
    tr.save
  end

end