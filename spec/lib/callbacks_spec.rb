require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Should put callbacks around save, create, update, and destroy by default" do

  before(:all) do

    TestResource.reload_resource_definition

    # This defines all the callbacks to check and see if they are fired
    TestResource.class_eval <<-EOE, __FILE__, __LINE__ + 1
      attr_accessor :s_val, :c_val, :u_val, :d_val
      before_save :bs_cb; after_save :as_cb
      before_create :bc_cb; after_create :ac_cb
      before_update :bu_cb; after_update :au_cb
      before_destroy :bd_cb; after_destroy :ad_cb
      
      def bs_cb
        @s_val = 1
      end
      def as_cb
        @s_val += 1
      end
      def bc_cb
        @c_val = 1
      end
      def ac_cb
       @c_val += 1
      end
      def bu_cb
        @u_val = 1
      end
      def au_cb
        @u_val += 1
      end
      def bd_cb
        @d_val = 1
      end
      def ad_cb
        @d_val += 1
      end
    EOE
  end
  
  it "should fire save and create callbacks when saving a new record" do
    tr = TestResource.new(:name => "Ethan", :age => 20)
    tr.save.should be_true
    tr.s_val.should eql(2)
    tr.c_val.should eql(2)
    tr.u_val.should be_nil
  end
  
  it "should fire save and update callbacks when updating a record" do
    tr = TestResource.new(:name => "Ethan", :age => 20)
    tr.stubs(:id => 1)
    tr.name = "Test"
    tr.age = 21
    tr.save.should be_true
    tr.s_val.should eql(2)
    tr.c_val.should be_nil
    tr.u_val.should eql(2)
  end
  
  it "should only fire destroy callbacks when destroying a record" do
    tr = TestResource.new(:name => "Ethan", :age => 20)
    tr.stubs(:id => 1)
    tr.destroy.should be_true
    tr.d_val.should eql(2)
    tr.s_val.should be_nil   
  end
  
end