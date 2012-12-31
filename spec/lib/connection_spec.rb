require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe Connection do
  
  it "should be able to set the token directly on ApiResource" do
    ApiResource.token = "123"
    ApiResource::Base.token.should eql "123"
  end
  
  it "should be able to set a default token value, which is passed through each request" do
    ApiResource::Mocks::Connection.expects(:get).with("/test_resources/1.json", {"Accept"=>"application/json", "Lifebooker-Token" => "abc"}).returns(ApiResource::Mocks::MockResponse.new({}))
    ApiResource::Base.token = "abc"
    TestResource.find(1)
  end

  it "should set the Lifebooker-Token if one is present for GET requests" do
    token = Kernel.rand(100000).to_s
    ApiResource::Mocks::Connection.expects(:get).with("/test_resources/1.json", {"Accept"=>"application/json", 'Lifebooker-Token' => "#{token}"}).returns(ApiResource::Mocks::MockResponse.new({}))

    ApiResource::Base.token = token

    TestResource.connection.get("/test_resources/1.json")
  end

  it "should set the Lifebooker-Token if one is present for DELETE requests" do
    token = Kernel.rand(100000).to_s
    ApiResource::Mocks::Connection.expects(:delete).with("/test_resources/1.json", {"Accept"=>"application/json", 'Lifebooker-Token' => "#{token}"}).returns(ApiResource::Mocks::MockResponse.new({}))

    ApiResource::Base.token = token

    TestResource.connection.delete("/test_resources/1.json")
  end

  it "should set the Lifebooker-Token if one is present for :head requests" do
    token = Kernel.rand(100000).to_s
    ApiResource::Mocks::Connection.expects(:head).with("/test_resources/1.json", {"Accept"=>"application/json", 'Lifebooker-Token' => "#{token}"}).returns(ApiResource::Mocks::MockResponse.new({}))

    ApiResource::Base.token = token

    TestResource.connection.head("/test_resources/1.json")
  end

  it "should set the Lifebooker-Token if one is present for POST requests" do
    token = Kernel.rand(100000).to_s
    ApiResource::Mocks::Connection.expects(:post).with("/test_resources/1.json", {}, {"Content-Type"=>"application/json", 'Lifebooker-Token' => "#{token}"}).returns(ApiResource::Mocks::MockResponse.new({}))

    ApiResource::Base.token = token

    TestResource.connection.post("/test_resources/1.json")
  end

  it "should set the Lifebooker-Token if one is present for PUT requests" do
    token = Kernel.rand(100000).to_s
    ApiResource::Mocks::Connection.expects(:put).with("/test_resources/1.json", {}, {"Content-Type"=>"application/json", 'Lifebooker-Token' => "#{token}"}).returns(ApiResource::Mocks::MockResponse.new({}))

    ApiResource::Base.token = token

    TestResource.connection.put("/test_resources/1.json")
  end

  it "should set its headers upon initialization" do
    token = Kernel.rand(100000).to_s
    ApiResource::Base.token = token

    TestResource.connection.headers.include?("Lifebooker-Token").should eql true
    TestResource.connection.headers["Lifebooker-Token"] = token
  end

  it "should reset headers upon initialization" do
    token = Kernel.rand(100000).to_s
    ApiResource::Base.token = token

    TestResource.connection.headers.include?("Lifebooker-Token").should eql true
    TestResource.connection.headers["Lifebooker-Token"] = token
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
  
  it "should provider a method to regenerate its connection" do
    conn = ApiResource::Base.connection
    conn.should be ApiResource::Base.connection
    ApiResource.reset_connection
    conn.should_not be ApiResource::Base.connection
  end
  
  context "No Mocks" do
    before(:all) do
      ApiResource::Mocks.remove
    end
    after(:all) do
      ApiResource::Mocks.init
      ApiResource.timeout = 10
      ApiResource.open_timeout = 10
    end
    it "should be able to set a timeout for its connection" do
      ApiResource.timeout = 1
      ApiResource.timeout.should eql 1
      ApiResource.open_timeout = 1
      ApiResource.open_timeout.should eql 1

      ApiResource::Base.connection.send(:http, "/test").options[:timeout].should eql 1
      ApiResource::Base.connection.send(:http, "/test").options[:open_timeout].should eql 1
      
      ApiResource.timeout = 100
      ApiResource::Base.connection.send(:http, "/test").options[:timeout].should eql 100

    end
    
    it "should time out if RestClient takes too long" do
      
      # hopefully google won't actually respond this fast :)
      ApiResource.timeout = 0.001
      ApiResource::Base.site = "http://www.google.com"
      lambda{
        ApiResource::Base.connection.get("/")
      }.should raise_error(ApiResource::RequestTimeout)
      
    end
    
  end

  context "headers" do

    it "should include the Lifebooker-Token in its headers" do

      old_token = ApiResource.token

      ApiResource.with_token("a") do
        TestResource.connection.headers["Lifebooker-Token"].should eql("a")
        ApiResource.with_token("b") do
          TestResource.connection.headers["Lifebooker-Token"].should eql("b")
        end
      end

      TestResource.connection.headers["Lifebooker-Token"].should eql(old_token)

    end

  end
  

  
end