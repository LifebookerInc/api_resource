require 'spec_helper'

module ApiResource
  module Associations
    
    describe BelongsToRemoteObjectProxy do

      before(:all) do
        TestResource.reload_resource_definition
      end

      context "#remote_path" do

        it "allows for custom named relationships and constructs the 
          correct remote path" do
          
          tr = TestResource.new(:custom_name_id => 123)
          tr.custom_name.remote_path.should eql(
            "/belongs_to_objects/123.json"
          )
        end

      end

    end
  end
end