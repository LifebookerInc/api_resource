require 'spec_helper'

describe ApiResource::AssociationBuilder::BelongsToBuilder do

  subject {
    ApiResource::AssociationBuilder::BelongsToBuilder.new(
      TestResource,
      :belongs_to_object
    )
  }

  context '#foreign_key' do

    it 'has the correct foreign key by default' do
      expect(subject.foreign_key).to eql(:belongs_to_object_id)
    end

  end

  context '#association_proxy' do

    it 'instantiates a single object proxy' do
      object = TestResource.new

      result = subject.association_proxy(object)
      expect(result).to be_instance_of(
        ApiResource::Associations::BelongsToProxy
      )
      expect(result.klass).to eql(BelongsToObject)
      expect(result.owner).to eql(object)
    end

  end

end