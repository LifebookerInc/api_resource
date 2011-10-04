require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'json'

include ApiResource

describe "Local" do
  
  it "should not go to the server to fetch a resource definition" do
    ApiResource::Connection.any_instance.expects(:get).never
    class MyTestResource < ApiResource::Local
      
    end
  end
  
end