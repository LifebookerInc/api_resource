require 'spec_helper'

describe ApiResource::Finders do

	before(:each) do
		TestResource.reload_resource_definition
	end

	it "should be able to find a single object" do
		TestResource.connection.expects(:get).with("/test_resources/1.json")

		TestResource.find(1)
	end

	it "should be able to find with parameters, params syntax" do
		TestResource.connection.expects(:get).with("/test_resources.json?active=true")
		TestResource.all(:params => {:active => true})
	end

	it "should be able to find with parameters without the params syntax" do
		TestResource.connection.expects(:get).with("/test_resources.json?active=true&passive=false")

		TestResource.all(:active => true, :passive => false)
	end

	it "should be able to chain find on top of a scope" do
		TestResource.connection.expects(:get).with("/test_resources.json?active=true&passive=true")
		TestResource.active.all(:passive => true)
	end

	it "should be able to chain find on top of an includes call" do
		TestResource.connection.expects(:get).with("/test_resources/1.json").returns({"id" => 1, "has_many_object_ids" => [1,2]})
		HasManyObject.connection.expects(:get).with("/has_many_objects.json?ids%5B%5D=1&ids%5B%5D=2").returns([])

		TestResource.includes(:has_many_objects).find(1)
	end

	it "should be able to use a scope with arguments" do
		TestResource.connection.expects(:get)
			.with("/test_resources.json?active=true&birthday%5Bdate%5D=5").returns([{"id" => 10}])

		res = TestResource.active.birthday(5).all
		res.should be_a(Array)
		res.first.id.should eql(10)
	end

	it "should be able to use a scope with multiple arguments" do
		TestResource.connection.expects(:get)
			.with("/test_resources.json?paginate%5Bcurrent_page%5D=10&paginate%5Bper_page%5D=5")
			.returns([{:id => 20}])

		res = TestResource.paginate(5, 10).all
		res.should be_a(Array)
		res.first.id.should eql(20)
	end

end