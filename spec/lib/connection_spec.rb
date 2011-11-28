require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe Connection do
  
  it "should be able to set the token directly on ApiResource" do
    ApiResource.token = "123"
    ApiResource::Base.token.should eql "123"
  end
  
  it "should be able to set a default token value, which is passed through each request" do
    TestResource.connection.expects(:get).with("/test_resources/1.json", "Lifebooker-Token" => "abc")
    ApiResource::Base.token = "abc"
    TestResource.find(1)
  end
  
  it "should be able to set a token for a given block" do
    ApiResource::Base.token = "123456"
    begin
      ApiResource.with_token("testing") do
        ApiResource::Base.token.should eql "testing"
        raise "AAAH"
      end
    rescue => e
      # should still reset the token
    end
    ApiResource::Base.token.should eql "123456"
  end
  
end