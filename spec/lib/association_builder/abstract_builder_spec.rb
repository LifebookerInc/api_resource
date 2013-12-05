require 'spec_helper'

describe ApiResource::AssociationBuilder::AbstractBuilder do

  context '.new' do

    subject { ApiResource::AssociationBuilder::AbstractBuilder }

    it 'sets its attributes based on the arguments' do
      record = subject.new(
        TestResource,
        :has_many_objects,
        class_name: 'BelongsToObject',
        foreign_key: 'made_up_foreign_key'
      )

      expect(record.owner_class).to eql(TestResource)
      expect(record.association_name).to eql(:has_many_objects)
      expect(record.association_class_name).to eql('BelongsToObject')
      expect(record.foreign_key).to eql(:made_up_foreign_key)
    end

    it 'sets defaults for unspecified arguments' do
      record = subject.new(
        TestResource,
        :has_many_objects
      )

      expect(record.owner_class).to eql(TestResource)
      expect(record.association_name).to eql(:has_many_objects)
      expect(record.association_class_name).to eql('HasManyObject')
      expect(record.foreign_key).to eql(:has_many_object_id)
    end

    it 'raises InvalidAssociationArguments if it gets bad arguments' do
      expect {
        subject.new(
          TestResource,
          class_name: 'BelongsToObject'
        )
      }.to raise_error(
        ArgumentError
      )
    end

  end

  context '#association_class' do

    subject {
      ApiResource::AssociationBuilder::AbstractBuilder.new(
        TestResource,
        :has_many_objects,
        class_name: 'BelongsToObject',
        foreign_key: 'made_up_foreign_key'
      )
    }

    it 'proxies the lookup to the ApiResource module' do
      ApiResource.expects(:lookup_constant)
        .with(
          TestResource,
          'BelongsToObject'
        ).returns(BelongsToObject)

      expect(subject.association_class).to eql(BelongsToObject)
    end

    it 'raises AssociationClassNotFound if it cannot find the class' do
      ApiResource.expects(:lookup_constant)
        .with(
          TestResource,
          'BelongsToObject'
        ).returns(nil)

      expect {
        subject.association_class
      }.to(
        raise_error ApiResource::AssociationBuilder::AssociationClassNotFound
      )
    end

  end

  context '#generated_methods_module' do

    subject {
      ApiResource::AssociationBuilder::AbstractBuilder.new(
        TestResource,
        :has_many_objects,
        class_name: 'BelongsToObject',
        foreign_key: 'made_up_foreign_key'
      )
    }

    it 'returns a module that includes the proper methods' do
      mod = subject.generated_methods_module
      # Put this module into a class since these are instance methods
      klass = Class.new do
        include mod
      end

      record = klass.new

      expect(record).to be_respond_to(:has_many_objects)
      expect(record).to be_respond_to(:has_many_objects=)
      expect(record).to be_respond_to(subject.foreign_key)
      expect(record).to be_respond_to("#{subject.foreign_key}=")
    end

  end

end