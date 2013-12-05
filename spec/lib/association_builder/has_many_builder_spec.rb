require 'spec_helper'

describe ApiResource::AssociationBuilder::HasManyBuilder do

  subject {
    ApiResource::AssociationBuilder::HasManyBuilder.new(
      TestResource,
      :has_many_objects
    )
  }

  context '#foreign_key' do

    it 'correctly pluralizes the foreign key' do
      expect(subject.foreign_key).to eql(:has_many_object_ids)
    end

  end

  context '#association_proxy' do

    it 'instantiates a multi object proxy' do
      object = TestResource.new

      result = subject.association_proxy(object)
      expect(result).to be_instance_of(
        ApiResource::Associations::MultiObjectProxy
      )
      expect(result.klass).to eql(HasManyObject)
      expect(result.owner).to eql(object)
    end

  end

end