require 'spec_helper'

describe ApiResource::Scopes::AbstractScope do

  subject {
    ApiResource::Scopes::AbstractScope
  }

  context '.factory' do

    it 'returns a default scope for normal parameters' do
      expect(
        subject.factory(:normal_scope, { arg1: :req, arg2: :req })
      ).to be_a(ApiResource::Scopes::DefaultScope)
    end

    it 'returns a variable arg scope if there are variable args' do
      expect(
        subject.factory(:var_arg_scope, { arg1: :req, arg2: :rest })
      ).to be_a(ApiResource::Scopes::VariableArgScope)
    end

    it 'returns a an optional arg scope if there are optional args' do
      expect(
        subject.factory(:opt_arg_scope, { arg1: :req, arg2: :opt })
      ).to be_a(ApiResource::Scopes::OptionalArgScope)
    end

  end

end