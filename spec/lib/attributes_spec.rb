require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Attributes" do
  
  after(:all) do
    TestResource.reload_class_attributes
  end
  
  context "Defining, getting, and setting attributes" do
    it "should be able to define known attributes" do
      TestResource.define_attributes :attr1, :attr2
      TestResource.attribute?(:attr1).should be_true
      TestResource.attribute?(:attr2).should be_true
    end
    
    it "should define methods for testing for reading and writing known attributes" do
      TestResource.define_attributes :attr1, :attr2
      tst = TestResource.new
      tst.respond_to?(:attr1).should be_true
      tst.respond_to?(:attr1=).should be_true
      tst.respond_to?(:attr1?).should be_true
    end
    
    it "should be able to set and change attributes" do
      TestResource.define_attributes :attr1, :attr2
      tst = TestResource.new
      tst.attr1.should be_nil
      tst.attr1?.should be_false
      tst.attr1 = "test"
      tst.attr1.should eql("test")
      tst.attr1?.should be_true
    end
    
    it "should be able to set multiple attributes at once" do
      TestResource.define_attributes :attr1, :attr2, :attr3
      tst = TestResource.new
      tst.attr3 = "123"
      
      tst.attributes = {:attr1 => "abc", :attr2 => "test"}
      tst.attr1.should eql "abc"
      tst.attr2.should eql "test"
      tst.attr3.should eql "123"
    end
    
  end
  
  context "Protected attributes" do
    it "should allow protected attributes that cannot be changed" do
      TestResource.define_protected_attributes :pattr3
      lambda {
        tst = TestResource.new
        tst.pattr3 = "test"
      }.should raise_error
    end
  end
  
  context "Dirty tracking" do
    context "Changes to attributes" do
      it "should implement dirty tracking for attributes" do
        TestResource.define_attributes :attr1, :attr2
        tst = TestResource.new
        tst.changed.should be_blank
        tst.attr1 = "Hello"
        tst.changed.include?("attr1").should be_true
        tst.changes.should_not be_blank
        
        # Set an attribute equal to itself
        tst.attr2 = tst.attr2
        tst.changes.include?("attr2").should be_false
      end

    end
    
    context "Resetting and marking attributes current" do
      
      before(:each) do
        TestResource.define_attributes :attr1, :attr2
      end
      
      it "should be able to mark any list of attributes as current (unchanged)" do
        tst = TestResource.new
        tst.attr1 = "Hello"
        tst.changed.should_not be_blank
        tst.set_attributes_as_current :attr1, :attr2
        tst.changed.should be_blank
      end
      
      it "should be able to mark all the attributes as current if none are given" do
        tst = TestResource.new
        tst.attr1 = "attr1"
        tst.attr2 = "attr2"
        tst.changed.should_not be_blank
        tst.set_attributes_as_current
        tst.changed.should be_blank
      end
      
      it "should be able to reset any list of attributes" do
        tst = TestResource.new
        tst.attr1 = "attr1"
        tst.reset_attribute_changes :attr1
        tst.attr1.should be_nil
        tst.changed.should be_blank
      end
      
      it "should be able to reset all the attributes if none are given" do
        tst = TestResource.new
        tst.attr1 = "attr1"
        tst.attr2 = "attr2"

        tst.reset_attribute_changes
        tst.attr1.should be_nil
        tst.attr2.should be_nil
        tst.changed.should be_blank
      end
    end
    
  end
  
end