require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Saving Resources with errors" do
  
  before(:all) do
    ErrorResource.include_root_in_json = true
  end
  
  context "Remote Errors" do
  
    it "should be able to handle errors as a hash" do
      t = ErrorResource.new(:name => "Ethan", :age => 12)
      t.save.should be_false
      t.errors.should_not be_nil
      t.errors['name'].should_not be_nil
    end
  
    it "should be able to handle errors as full messages" do
      t = ErrorFullMessageResource.new(:name => "Ethan", :age => 12)
      t.save.should be_false
      t.errors.should_not be_nil
      t.errors['name'].should_not be_nil
    end
    
  end
  
end