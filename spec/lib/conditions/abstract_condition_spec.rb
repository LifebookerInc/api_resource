require 'spec_helper'

describe "Conditions" do

	before(:each) do
		TestResource.reload_resource_definition
	end

	it "should chain scopes onto the base class" do

		obj = TestResource.active
		obj.should be_a ApiResource::Conditions::ScopeCondition

		obj2 = TestResource.paginate

		TestResource.expects(:paginate).returns(obj2)

		obj3 = obj.paginate

		obj3.to_query.should eql("active=true&page=1&per_page=10")
		obj3.should_not be_eager_load
		obj3.should_not be_blank_conditions
		# Make sure that it clones

		obj3.object_id.should_not eql(obj.object_id)
		obj3.object_id.should_not eql(obj2.object_id)
	end

	it "should properly deal with calling includes" do
		obj = TestResource.includes(:has_many_objects).active

		obj.should be_eager_load
		obj.should_not be_blank_conditions
		obj.association.should be_nil
		obj.to_query.should eql("active=true")
		obj.included_objects.should eql([:has_many_objects])
	end

	it "should be able to chain includes and scopes" do
		obj = TestResource.includes(:has_many_objects).active.includes(:belongs_to_object)

		obj.should be_eager_load
		obj.should_not be_blank_conditions
		obj.included_objects.should eql([:has_many_objects, :belongs_to_object])
	end

	it "should be able to include multiple includes in the same call" do
		obj = TestResource.includes(:has_many_objects, :belongs_to_object)

		obj.should be_eager_load
		obj.should be_blank_conditions
		obj.included_objects.should eql([:has_many_objects, :belongs_to_object])
	end

	it "should raise an error if given an include that isn't a valid association" do
		lambda {
			TestResource.includes(:fake_assoc)
		}.should raise_error
	end

	it "should create a resource finder when forced to load, and cache the result" do
		obj = TestResource.includes(:has_many_objects)

		resource_finder_mock = mock(load: [1], first: 1)

		ApiResource::Finders::ResourceFinder.expects(:new)
			.with(TestResource, obj)
			.returns(resource_finder_mock)

		obj.internal_object.should eql(resource_finder_mock)
		obj.all.should eql(resource_finder_mock)
		obj.first.should eql(1)
	end

	it "should proxy calls to enumerable and array methods to the loaded
		object" do

		obj = TestResource.includes(:has_many_objects)

		# this just needs to call each
		resource_finder_mock = mock(load: true, each: true)

		ApiResource::Finders::ResourceFinder.expects(:new)
			.with(TestResource, obj)
			.returns(resource_finder_mock)

		obj.collect{|o| o * 2}.should eql([])
	end

	it "should not typecast nil and false to true when creating condition hashes" do
		obj = TestResource.boolean(false, nil)
		hsh = obj.to_hash["boolean"]
		hsh["a"].should eql(false)
		hsh.should be_key(:b)
	end

end