require 'spec_helper'

describe ApiResource::Scopes::OptionalArgScope do

  subject {
    ApiResource::Scopes::OptionalArgScope
  }

  context 'creating a new scope' do

    it 'sets the proper attributes' do
      result = subject.new(:optional_scope, { arg1: :req, arg2: :opt })
      expect(result.name).to eql(:optional_scope)
      expect(result.arg_names).to eql([:arg1, :arg2])
      expect(result.arg_types).to eql([:req, :opt])
      expect(result.required_arg_names).to eql([:arg1])
      expect(result.optional_arg_names).to eql([:arg2])
    end

    it 'rejects scopes without any optional arguments' do
      expect {
        subject.new(:optional_scope, { arg1: :req, arg2: :req })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

    it 'rejects scopes that have variable args' do
      expect {
        subject.new(:optional_scope, { arg1: :req, arg2: :opt, arg3: :rest })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

    it 'rejects scopes that interleave required and optional args' do
      expect {
        subject.new(:optional_scope, { arg1: :req, arg2: :opt, arg3: :req })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

  end

  context '#apply' do

    subject {
      ApiResource::Scopes::OptionalArgScope.new(
        :optional_scope,
        { arg1: :req, arg2: :req, arg3: :opt }
      )
    }

    it 'creates a scope condition with the proper args' do
      result = subject.apply(TestResource, 1, 2, 3)
      expect(result).to be_a(ApiResource::Conditions::WhereCondition)
      expect(result.klass).to eql(TestResource)
      expect(result.conditions['optional_scope']['arg1']).to eql(1)
      expect(result.conditions['optional_scope']['arg3']).to eql(3)
    end

    it 'has the proper args when the optional arg is left out' do
      result = subject.apply(TestResource, 1, 2)
      expect(result.conditions['optional_scope']['arg2']).to eql(2)
      expect(result.conditions['optional_scope'].key?('arg3')).to be_false
    end

    it 'fails if less than the number of required args are provided' do
      expect {
        subject.apply(TestResource, 1)
      }.to raise_error(ApiResource::Scopes::InvalidArgument)
    end

    it 'fails if too many arguments are provided' do
      expect {
        subject.apply(TestResource, 1, 2, 3, 4)
      }.to raise_error(ApiResource::Scopes::InvalidArgument)
    end

  end

end