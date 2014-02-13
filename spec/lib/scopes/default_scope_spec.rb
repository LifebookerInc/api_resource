require 'spec_helper'

describe ApiResource::Scopes::DefaultScope do

  subject {
    ApiResource::Scopes::DefaultScope
  }

  context 'creating a new scope' do

    it 'sets the proper attributes' do

      result = subject.new(:normal_scope, { arg1: :req, arg2: :req })

      expect(result.name).to eql(:normal_scope)
      expect(result.arg_names).to eql([:arg1, :arg2])
      expect(result.arg_types).to eql([:req, :req])
    end

    it 'raises an error if the argument types are not req' do
      expect {
        subject.new(:invalid_scope, { arg1: :req, arg2: :opt })
      }.to raise_error(ApiResource::Scopes::InvalidDefinition)
    end

  end

  context '#apply' do

    subject {
      ApiResource::Scopes::DefaultScope.new(
        :normal_scope,
        { arg1: :req, arg2: :req }
      )
    }

    it 'creates a scope condition object with the proper args' do
      result = subject.apply(TestResource, 1, 2)
      expect(result).to be_a(ApiResource::Conditions::ScopeCondition)
      expect(result.klass).to eql(TestResource)
      expect(result.conditions['normal_scope']['arg1']).to eql(1)
      expect(result.conditions['normal_scope']['arg2']).to eql(2)
    end

    it 'raises the proper error when the arity it wrong' do
      expect {
        subject.apply(TestResource, 1)
      }.to raise_error(ApiResource::Scopes::InvalidArgument)
    end

  end


end