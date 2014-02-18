require 'spec_helper'

describe ApiResource::Decorators::AsyncDecorator do

  subject {
    ApiResource::Decorators::AsyncDecorator
  }

  context 'Loading data' do

    it 'returns the proper result with no block' do
      obj = subject.new(mock(internal_object: [1,2,3]))
      expect(obj.value).to eql([1,2,3])
    end

    it 'returns the proper result when a block is given' do
      obj = subject.new(mock(internal_object: [1,2,3])) do |results|
        results.collect { |i| i + 1 }
      end

      expect(obj.value).to eql([2,3,4])
    end

    it 'happens in the background' do
      tmp_val = 1
      obj = subject.new(mock(internal_object: [1,2,3])) do |results|
        sleep(0.1)
        tmp_val += 1
        results
      end

      expect(tmp_val).to eql(1)
      expect(obj.value).to eql([1,2,3])
      expect(tmp_val).to eql(2)
    end

  end

  context 'Proxying Methods' do
    it 'proxies methods to the result of the future' do
      obj = subject.new(mock(internal_object: [1,2,3]))
      expect(obj.first).to eql(1)
    end
  end

end