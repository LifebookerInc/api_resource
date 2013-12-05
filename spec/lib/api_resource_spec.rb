require 'spec_helper'

describe ApiResource do

  context ".cache" do

    before(:each) do
      if defined?(Rails)
        Object.send(:remove_const, :Rails)
      end
    end

    after(:each) do
      if defined?(Rails)
        Object.send(:remove_const, :Rails)
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

  context '.lookup_constant' do

    it 'finds things that are specified in the root namespace' do
      expect(
        ApiResource.lookup_constant(ApiResource::Base, '::TestResource')
      ).to eql(
        TestResource
      )
    end

    it 'finds things in the base namespace when for a root level class' do
      expect(
        ApiResource.lookup_constant(BelongsToObject, 'TestResource')
      ).to eql(
        TestResource
      )
    end

    it 'finds things namespaced under the base class' do
      expect(
        ApiResource.lookup_constant(ApiResource, 'Base')
      ).to eql(
        ApiResource::Base
      )
    end

    it 'finds things in a middle namespace' do
      expect(
        ApiResource.lookup_constant(
          TestMod::InnerMod::InnerClass,
          'SecondInnerClass'
        )
      ).to eql(
        TestMod::InnerMod::SecondInnerClass
      )
    end

  end

end