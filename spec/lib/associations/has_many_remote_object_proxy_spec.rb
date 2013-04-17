require 'spec_helper'

module ApiResource
  module Associations
    
    describe HasManyRemoteObjectProxy do

      before(:all) do
        TestResource.reload_resource_definition
      end

      context "#<<" do
        
        it "implements the shift operator" do
          tr = TestResource.new
          tr.has_many_objects << HasManyObject.new

          tr.has_many_objects.length.should be 1
        end

      end

      context "#load" do

        it "does a find based on its set of ids if present" do
          tr = TestResource.new
          tr.has_many_object_ids = [1,2]

          HasManyObject.connection.expects(:get)
            .with("/has_many_objects.json?ids%5B%5D=1&ids%5B%5D=2")
            .returns([{"name" => "Test"}])

          tr.has_many_objects.length.should be 1
          tr.has_many_objects.first.name.should eql("Test")

        end

      end

    end
  end
end