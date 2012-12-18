require 'spec_helper'

describe ApiResource::Associations::AssociationScope do

  before(:all) do
    TestResource.reload_resource_definition
  end

  context "#remote_path" do

    it "should provide access to its remote path when 
      instantiated through a parent" do

      test_resource = TestResource.find(1)
      test_resource.has_many_service_uri.remote_path.should eql(
        "/test_resource/1/has_many"
      )

    end

  end

end