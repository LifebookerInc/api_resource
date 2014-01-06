require 'spec_helper'

describe "MultiObjectAssociationFinder" do

	before(:each) do
		TestResource.reload_resource_definition
	end

	context "#load" do

		it "should build a proper load path and call into the connection" do
			TestResource.connection.expects(:get).with("test_resources.json?id[]=1&id[]=2").returns([])

			ApiResource::Finders::MultiObjectAssociationFinder.new(
				TestResource,
				stub(remote_path: "test_resources", to_query: "id[]=1&id[]=2", :blank_conditions? => false)
			).load
		end

		it "should load a has many association properly" do
			# much of this test already lies in resource_finder_spec.rb
			# this just verifies that the data is passed in correctly
			finder = ApiResource::Finders::MultiObjectAssociationFinder.new(
				TestResource,
				stub(
					remote_path: "test_resources",
					blank_conditions?: true,
					eager_load?: true,
					included_objects: [:has_many_objects]
				)
			)

			tr = TestResource.new
			tr.stubs(:id).returns(1)
			tr.stubs(:has_many_object_ids).returns([1,2])
			TestResource.connection.expects(:get).with("test_resources.json").returns([4])
			TestResource.expects(:instantiate_collection).with([4]).returns([tr])

			finder.expects(:load_includes).with(has_many_objects: [1,2]).returns(5)
			finder.expects(:apply_includes).with([tr], 5).returns(6)

			finder.load.should eql([tr])
		end
	end

	context "#select" do

		it "properly sends #select to its internal object" do

			TestResource.connection.stubs(:get)
				.with("test_resources.json?id[]=1&id[]=2")
				.returns([{"name" => "Dan"}])

			finder = ApiResource::Finders::MultiObjectAssociationFinder.new(
				TestResource,
				stub(
					remote_path: "test_resources",
					to_query: "id[]=1&id[]=2",
					blank_conditions?: false,
					included_objects: [],
					eager_load?: true
				)
			)

			expect(finder.select{|r| r.name == 'Dan'}.length).to eql(1)

		end

	end

end