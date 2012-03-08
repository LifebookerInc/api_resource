require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'json'

include ApiResource

describe Mocks do
  
  # we set up the mocks in spec helper, so we can just assert this
  it "should hijack the connection" do
    ApiResource::Mocks::Interface.any_instance.expects(:get).once.returns(
      ApiResource::Mocks::MockResponse.new({}, {:headers => {"Content-type" => "application/json"}, :status_code => 200})
    )
    TestResource.reload_class_attributes
  end
  
  it "should allow the user to raise errors for invalid responsed" do
    old_err_status = ApiResource.raise_missing_definition_error 
    ApiResource::Base.raise_missing_definition_error = true
    
    lambda {
      class MyNewInvalidResource < ApiResource::Base; end
      MyNewInvalidResource.new 
    }.should raise_error(ApiResource::ResourceNotFound)
    
    ApiResource.raise_missing_definition_error = old_err_status
  end
  
end