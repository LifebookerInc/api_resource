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
          mock(:test_resource_id= => 2),
          mock(:test_resource_id= => 2)
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

  context '#assign'

end