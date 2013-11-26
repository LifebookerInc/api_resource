require 'spec_helper'

describe "ResourceFinder" do

	before(:each) do
		TestResource.reload_resource_definition
	end

	it "should load normally without includes using connection.get" do
		TestResource.connection.expects(:get).with("/test_resources.json")

		ApiResource::Finders::ResourceFinder.new(
			TestResource,
			mock(:to_hash => {})
		).load
	end

	it "should pass conditions into the connection get method" do
		TestResource.connection.expects(:get).with("/test_resources.json?ids%5B%5D=1&ids%5B%5D=2&ids%5B%5D=3")

		ApiResource::Finders::ResourceFinder.new(
			TestResource,
			mock(:to_hash => {:ids => [1,2,3]})
		).load
	end

	it "should try to load includes if it finds an object" do
		obj_mock = {:id => 1}

		TestResource.connection.expects(:get).with("/test_resources.json").returns([obj_mock])

		obj = ApiResource::Finders::ResourceFinder.new(
			TestResource,
			stub(:to_hash => {}, :eager_load? => false, :included_objects => [])
		).load

	#	obj.first.id.should eql(1)
	end

	it "should load and distribute includes among the returned objects" do
		inc_mock = {:id => 1}
		inc_mock2 = {:id => 2}

		TestResource.connection.expects(:get)
				.with("/test_resources.json")
				.returns([{:id => 1, :has_many_object_ids => [1,2]}])

		HasManyObject.connection.expects(:get)
				.with("/has_many_objects.json?ids%5B%5D=1&ids%5B%5D=2")
				.returns([inc_mock, inc_mock2])

		obj = ApiResource::Finders::ResourceFinder.new(
			TestResource,
			stub(:to_hash => {}, :eager_load? => true, :included_objects => [:has_many_objects])
		).load
		obj.first.has_many_objects.collect(&:id).should eql([1,2])
	end

	it "should work with loading for multiple objects" do
		TestResource.connection.expects(:get).with("/test_resources.json").returns([
			{:id => 1, :has_many_object_ids => [1]},
			{:id => 2, :has_many_object_ids => [2]}
		])
		HasManyObject.connection.expects(:get)
								 .with("/has_many_objects.json?ids%5B%5D=1&ids%5B%5D=2")
								 .returns([{:id => 1}, {:id => 2}])

		obj = ApiResource::Finders::ResourceFinder.new(
			TestResource,
			stub(:to_hash => {}, :eager_load? => true, :included_objects => [:has_many_objects])
		).load

		obj.first.has_many_objects.collect(&:id).should eql([1])
		obj.second.has_many_objects.collect(&:id).should eql([2])
	end

	context 'Headers returned from the server' do

		context '#total_entries' do

			it 'stores the ApiResource-Total-Entries as total_entries' do

				finder = ApiResource::Finders::ResourceFinder.new(
					TestResource,
					ApiResource::Conditions::PaginationCondition.new(
						TestResource,
						{ page: 2, per_page: 10 }
					)
				)

				finder.load

				expect(finder.total_entries).to be 100


			end

		end

	end

end