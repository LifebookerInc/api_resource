require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'json'

include ApiResource

describe "Local" do
  
  it "should not go to the server to fetch a resource definition" do
    ApiResource::Connection.any_instance.expects(:get).never
    class MyTestResource < ApiResource::Local
      scope :test, {:test => true}
    end
    mtr = MyTestResource.new
    # should still have scopes

    MyTestResource.expects(:clear_attributes).never
    MyTestResource.expects(:clear_related_objects).never

    MyTestResource.reload_resource_definition
    mtr.scopes.should_not be_blank
    
  end
  
end