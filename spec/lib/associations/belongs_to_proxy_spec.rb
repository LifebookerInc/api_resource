require 'spec_helper'

describe ApiResource::Associations::BelongsToProxy do

  TestResource.class_eval do
    belongs_to :belongs_to_object
  end

  subject {
    test_resource.belongs_to_object
  }

  let(:test_resource) { TestResource.new }

  context '#read_foreign_key' do

    it 'proxies the call onto the owned resource' do
      test_resource.expects(:read_attribute)
        .with(:belongs_to_object_id)
        .returns(5)

      expect(
        subject.read_foreign_key
      ).to eql(5)
    end

  end

  context '#write_foreign_key' do

    it 'proxies the call onto the owned resource' do
      test_resource.expects(:write_attribute)
        .with(:belongs_to_object_id, 5)
        .returns(5)

      expect(
        subject.write_foreign_key(5)
      ).to eql(5)
    end

    it 'reads the new value correctly' do
      expect(
        subject.read_foreign_key
      ).to be_nil

      subject.write_foreign_key(5)

      expect(
        subject.read_foreign_key
      ).to eql(5)
    end

  end

  context '#assign' do

    let(:belongs_to_object) { BelongsToObject.new }

    it 'allows setting the association to an instance of the proper class' do
      expect(
        subject.assign(belongs_to_object)
      ).to eql(belongs_to_object)

      expect(subject.internal_object).to eql(belongs_to_object)
    end

    it 'allows setting the association to an instance of a subclass' do
      belongs_to_child = BelongsToChild.new
      expect(
        subject.assign(belongs_to_child)
      ).to eql(belongs_to_child)

      expect(subject.internal_object).to eql(belongs_to_child)
    end

    it 'does not allow setting to an instance of the wrong class' do
      expect {
        subject.assign(TestResource.new)
      }.to raise_error ApiResource::Associations::AssociationTypeMismatch
    end

    it 'properly updates the foreign key after assigning' do
      expect(
        subject.read_foreign_key
      ).to be_nil

      belongs_to_object.stubs(:id).returns(10)
      subject.assign(belongs_to_object)

      expect(
        subject.read_foreign_key
      ).to eql(10)
    end

    it 'clears the foreign key field after assigning to nil' do
      subject.write_foreign_key(10)

      subject.assign(nil)

      expect(
        subject.read_foreign_key
      ).to be_nil
    end

  end

end