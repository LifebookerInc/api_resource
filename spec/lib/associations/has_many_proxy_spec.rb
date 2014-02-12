require 'spec_helper'

describe ApiResource::Associations::HasManyProxy do

  TestResource.class_eval do
    has_many :has_many_objects
  end

  subject {
    test_resource.has_many_objects
  }

  let(:test_resource) { TestResource.new }

  context '#read_foreign_key' do
    it 'reads the foreign key from the record itself if it exists' do
      test_resource.expects(:read_attribute)
                   .with(:has_many_object_ids)
                   .returns([1,2,3])

      expect(
        subject.read_foreign_key
      ).to eql([1,2,3])
    end

    it 'if the foreign key on the record is nil it attempts to load it' do
      ApiResource::Finders::MultiObjectFinder
        .any_instance
        .expects(:internal_object)
        .returns([
          mock(id: 1),
          mock(id: 2)
        ])

      expect(
        subject.read_foreign_key
      ).to eql([1,2])
    end
  end

  context '#write_foreign_key' do
    it 'forces loading and sets the proper attribute on the results' do
      HasManyObject
        .expects(:find)
        .with(1,2)
        .returns([
          mock(:write_attribute),
          mock(:write_attribute)
        ])

      test_resource
        .stubs(:read_attribute)
        .with(:id)
        .returns(2)

      expect(
        subject.write_foreign_key([1,2])
      ).to eql([1,2])
    end
  end

  context '#assign' do

    let(:has_many_objects) { [ HasManyObject.new ] }

    it 'allows setting the association to an array of the proper class' do
      expect(
        subject.assign(has_many_objects)
      ).to eql(has_many_objects)

      expect(
        subject.internal_object
      ).to eql(has_many_objects)
    end

    it 'allows setting the association to an array of a subclass' do
      children = [ HasManyChild.new ]
      expect(
        subject.assign(children)
      ).to eql(children)

      expect(subject.internal_object).to eql(children)
    end

    it 'does not allow setting to an array of the wrong class' do
      expect {
        subject.assign( [ TestResource.new ] )
      }.to raise_error ApiResource::Associations::AssociationTypeMismatch
    end

    it 'typecasts nil to a blank array and clears the foreign key' do
      expect(
        subject.assign(nil)
      ).to eql([])

      expect(
        subject.internal_object
      ).to eql([])
    end

    it 'sets the foreign keys of the new objects' do
      test_resource.stubs(:read_attribute).with(:id).returns(10)

      expect(
        subject.assign(has_many_objects)
      ).to eql(has_many_objects)

      expect(
        subject.internal_object.all? { |o|
          o.read_attribute(:test_resource_id) == 10
        }
      ).to be_true
    end


  end

end