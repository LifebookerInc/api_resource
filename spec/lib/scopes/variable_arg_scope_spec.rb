require 'spec_helper'

describe ApiResource::Scopes::VariableArgScope do

  subject {
    ApiResource::Scopes::VariableArgScope
  }

  context 'creating a new scope' do

    it 'sets the proper attributes' do
      result = subject.new(
        :var_arg_scope,
        { arg1: :req, arg2: :req, arg3: :rest }
      )
      expect(result.name).to eql(:var_arg_scope)
      expect(result.arg_names).to eql([:arg1, :arg2, :arg3])
      expect(result.required_arg_names).to eql([:arg1, :arg2])
      expect(result.rest_arg_name).to eql(:arg3)
    end

    it 'rejects scopes without a :rest argument' do
      expect {
        subject.new(:var_arg_scope, { arg1: :req, arg2: :req })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

    it 'rejects scope with :opt arguments' do
      expect {
        subject.new(:var_arg_scope, { arg1: :req, arg2: :opt, arg3: :rest })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

    it 'rejects scopes with more than one :rest argument' do
      expect {
        subject.new(:var_arg_scope, { arg1: :req, arg2: :rest, arg3: :rest })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

    it 'rejects scopes with :rest as anything but the last argument' do
      expect {
        subject.new(:var_arg_scope, { arg1: :rest, arg2: :req })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

  end

  context '#apply' do

    subject {
      ApiResource::Scopes::VariableArgScope.new(
        :var_arg_scope,
        { arg1: :req, arg2: :rest }
      )
    }

    it 'creates a scope condition with the proper args' do
      result = subject.apply(TestResource, 1, 2, 3)
      expect(result).to be_a(ApiResource::Conditions::WhereCondition)
      expect(result.klass).to eql(TestResource)
      expect(result.conditions['var_arg_scope']['arg1']).to eql(1)
      expect(result.conditions['var_arg_scope']['arg2']).to eql([2, 3])
    end

    it 'has the proper args when the rest arg is blank' do
      result = subject.apply(TestResource, 1)
      expect(result.conditions['var_arg_scope']['arg1']).to eql(1)
      expect(result.conditions['var_arg_scope']['arg2']).to eql([])
    end

    it 'fails if less than the number of required args are provided' do
      expect {
        subject.apply(TestResource)
      }.to raise_error(ApiResource::Scopes::InvalidArgument)
    end

  end

end