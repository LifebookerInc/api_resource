require 'spec_helper'

describe ApiResource::Associations::HasOneProxy do

  TestResource.class_eval do
    has_one :has_one_object
  end

  subject {
    test_resource.has_one_object
  }

  let(:test_resource) { TestResource.new }

  # No need to test assign because it is tested by the
  # belongs to proxy tests
  context '#read_foreign_key' do

    it 'forces the object to load by calling internal object' do
      expectation = mock()
      expectation.expects(:read_attribute)
                 .with(:id)
                 .returns(5)

      subject.expects(:internal_object).returns(
        expectation
      )

      expect(
        subject.read_foreign_key
      ).to eql(5)
    end

  end

  context '#write_foreign_key' do

    it 'forces a load of the new object' do
      HasOneObject.expects(:find)
                  .with(5)
                  .returns(
                    stub(
                      read_attribute: 5
                    )
                  )

      expect(
        subject.write_foreign_key(5)
      ).to eql(5)

      # Make sure it short circuits if you assign is the same value twice
      expect(
        subject.write_foreign_key(5)
      ).to eql(5)

      expect(
        subject.read_foreign_key
      ).to eql(5)
    end

  end

end