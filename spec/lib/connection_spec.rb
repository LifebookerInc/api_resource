require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe Connection do
  
  it "should be able to set a default token value, which is passed through each request" do
    TestResource.connection.expects(:get).with("/test_resources/1.json", "Lifebooker-Token" => "abc")
    ApiResource::Base.token = "abc"
    TestResource.find(1)
  end
  
end