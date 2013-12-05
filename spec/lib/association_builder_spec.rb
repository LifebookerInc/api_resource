require 'spec_helper'

describe ApiResource::AssociationBuilder do

  subject { ApiResource::AssociationBuilder }

  context '.get_class' do

    it 'returns the proper subclass for has_many' do
      expect(
        subject.get_class(:has_many)
      ).to eql(
        ApiResource::AssociationBuilder::HasManyBuilder
      )
    end

  end

end