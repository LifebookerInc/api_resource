require 'spec_helper'

module ApiResource
  module Associations
    
    describe HasOneRemoteObjectProxy do

      before(:all) do
        TestResource.reload_resource_definition
      end

      context "#load" do
        
        it "correctly loads data from an endpoint that returns
          a single record" do
          
          tr = TestResource.new(
            :has_one_object => {:service_uri => "/has_one_objects/1.json"} 
          )
          tr.has_one_object.internal_object.should be_instance_of(
            HasOneObject
          )
        end

      end

    end
  end
end