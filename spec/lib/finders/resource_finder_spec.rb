require 'spec_helper'

describe "ResourceFinder" do

	before(:each) do
		TestResource.reload_resource_definition
	end

	it "should call find on the class normally without includes" do
		TestResource.expects(:find).with(:all, {})

		ApiResource::Finders::ResourceFinder.new(
			TestResource,
			mock(:to_hash => {})
		).find
	end

	it "should pass conditions into the finder method" do
		TestResource.expects(:find).with(:all, {:id => [1,2,3]})

		ApiResource::Finders::ResourceFinder.new(
			TestResource, 
			mock(:to_hash => {:id => [1,2,3]})
		).find
	end

	it "should try to load includes if it finds an object" do
		obj_mock = mock(:id => 1)

		TestResource.expects(:find).with(:all, {}).returns([obj_mock])

		obj = ApiResource::Finders::ResourceFinder.new(
			TestResource,
			stub(:to_hash => {}, :eager_load? => false, :included_objects => [])
		).find

		obj.first.id.should eql(1)
	end

	it "should load and distribute includes among the returned objects" do
		inc_mock = stub(:id => 1)
		inc_mock2 = stub(:id => 2)

		tr = TestResource.new
		tr.stubs(:id).returns(1)
		tr.stubs(:has_many_object_ids).returns([1,2])
		tr.expects(:has_many_objects=).with([inc_mock, inc_mock2])
		tr.expects(:has_many_objects).returns([inc_mock, inc_mock2])

		TestResource.expects(:find).with(:all, {}).returns([tr])

		HasManyObject.expects(:find).with(:all, :id => [1,2]).returns([inc_mock, inc_mock2])

		obj = ApiResource::Finders::ResourceFinder.new(
			TestResource,
			stub(:to_hash => {}, :eager_load? => true, :included_objects => [:has_many_objects])
		).find
		obj.first.has_many_objects.collect(&:id).should eql([1,2])
	end

	it "should work with loading for multiple objects" do
		inc_mock = stub(:id => 1)
		inc_mock2 = stub(:id => 2)

		tr = TestResource.new
		tr.stubs(:id).returns(1)
		tr.stubs(:has_many_object_ids).returns([1])
		tr.expects(:has_many_objects=).with([inc_mock]).returns([inc_mock])
		tr.expects(:has_many_objects).returns([inc_mock])

		tr2 = TestResource.new
		tr2.stubs(:id).returns(2)
		tr2.stubs(:has_many_object_ids).returns([2])
		tr2.expects(:has_many_objects=).with([inc_mock2]).returns([inc_mock2])
		tr2.expects(:has_many_objects).returns([inc_mock2])

		TestResource.expects(:find).with(:all, {}).returns([tr, tr2])
		HasManyObject.expects(:find).with(:all, :id => [1,2]).returns([inc_mock2, inc_mock])

		obj = ApiResource::Finders::ResourceFinder.new(
			TestResource,
			stub(:to_hash => {}, :eager_load? => true, :included_objects => [:has_many_objects])
		).find

		obj.first.has_many_objects.collect(&:id).should eql([1])
		obj.second.has_many_objects.collect(&:id).should eql([2])
	end

end