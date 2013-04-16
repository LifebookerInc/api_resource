require 'spec_helper'

module ApiResource
  module Associations
    
    describe HasManyRemoteObjectProxy do

      context "#<<" do
        
        it "implements the shift operator" do
          tr = TestResource.new
          tr.has_many_objects << HasManyObject.new

          tr.has_many_objects.length.should be 1
        end

      end

    end
  end
end