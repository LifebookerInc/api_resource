require 'spec_helper'

describe "With Prefixes" do

	let(:prefix_model) do
		PrefixModel.new({:foreign_key_id => "123", :name => "test"})
	end

	context "#create" do

		it "should use the prefix" do
			prefix_model.send(:connection).expects(:post)
				.with(
					"/foreign/123/prefix_models.json", 
					{"prefix_model" => {"name" => "test"}}.to_json,
					instance_of(Hash)
				)
			prefix_model.save
		end

	end

	context "#first" do

		it "should use the prefix to find records" do
			prefix_model.send(:connection).expects(:get)
				.with(
					"/foreign/123/prefix_models.json", 
					instance_of(Hash)
				)
				.returns([])
			PrefixModel.first(:params => {:foreign_key_id => 123})
		end

	end

	context "#destroy" do

		it "should use the prefix" do

			prefix_model.id = 456
			prefix_model.send(:connection).expects(:delete)
				.with(
					"/foreign/123/prefix_models/456.json",
					instance_of(Hash)
				)
			prefix_model.destroy

		end

	end

	context "#update" do

		it "should use the prefix" do

			prefix_model.id = 456
			prefix_model.name = "changed name"
			prefix_model.send(:connection).expects(:put)
				.with(
					"/foreign/123/prefix_models/456.json", 
					{"prefix_model" => {"name" => "changed name"}}.to_json,
					instance_of(Hash)
				)
			prefix_model.save

		end

	end

end