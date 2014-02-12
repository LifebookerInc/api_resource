require 'spec_helper'

describe ApiResource::AssociationBuilder::HasOneBuilder do

  subject {
    ApiResource::AssociationBuilder::HasOneBuilder.new(
      TestResource,
      :has_one_object
    )
  }

  context '#foreign_key' do

    it 'has the correct foreign key by default' do
      expect(subject.foreign_key).to eql(:test_resource_id)
      expect(subject.foreign_key_method).to eql(:has_one_object_id)
    end

  end

  context '#association_proxy' do

    it 'instantiates a multi object proxy' do
      object = TestResource.new

      result = subject.association_proxy(object)
      expect(result).to be_instance_of(
        ApiResource::Associations::HasOneProxy
      )
      expect(result.klass).to eql(HasOneObject)
      expect(result.owner).to eql(object)
    end

  end

  context '#association_type' do

    it 'returns the proper association type' do
      expect(subject.association_type).to eql(:has_one)
    end

  end

end