require 'spec_helper'

describe ApiResource do

  context ".cache" do

    around(:each) do |example|
      begin
        old_rails = Object.send(:remove_const, :Rails)
        example.run
      ensure
        Rails = old_rails
        ApiResource
      end
    end

    it "should be a Rails cache if it's initialized" do
      cache_stub = stub()
      Rails = mock(:cache => cache_stub)
      ApiResource.cache(true).should be cache_stub
    end

    it "should default to an instance of memory cache" do
      defined?(Rails).should be_blank
      ApiResource.cache(true).should be_a(
        ActiveSupport::Cache::MemoryStore
      )
    end
  end

  context ".with_ttl" do

    it "should temporarily set ttl for a block" do
      old_ttl = ApiResource.ttl
      ApiResource.with_ttl(10) do
        ApiResource.ttl.should eql(10)
      end
      ApiResource.ttl.should eql(old_ttl)
    end

  end

end