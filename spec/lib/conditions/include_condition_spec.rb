require 'spec_helper'

describe ApiResource::Conditions::IncludeCondition do

  before(:all) do
    TestResource.class_eval do
      has_many :ic_assoc
      belongs_to :ic_assoc2

      scope :ic_scope, {}
    end
  end

  context 'Holding onto included associations' do

    it 'works when called directly on a class' do
      included = TestResource.includes(:ic_assoc)

      expect(included.included_associations).to eql([:ic_assoc])
    end

    it 'works with multiple include calls' do
      included = TestResource.includes(:ic_assoc).includes(:ic_assoc2)

      expect(included.included_associations).to eql([:ic_assoc, :ic_assoc2])
    end

    it 'works when chained on top of another scope' do
      included = TestResource.ic_scope.includes(:ic_assoc2)

      expect(included.included_associations).to eql([:ic_assoc2])
    end

    it 'works when another scope is chained on top of it' do
      included = TestResource.includes(:ic_assoc).ic_scope
      expect(included.included_associations).to eql([:ic_assoc])
    end

    it 'raises an error if the association is unknown' do
      expect {
        TestResource.includes(:fake_assoc)
      }.to raise_error ApiResource::Associations::UnknownEagerLoadAssociation
    end

  end

end