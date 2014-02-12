require 'spec_helper'

describe ApiResource::Scopes do

  before(:all) do
    ScopeResource.class_eval do
      scope :no_arg, {}
      scope :opt_args, { arg1: :opt }
      scope :var_args, { ids: :rest }
    end

    ChildScopeResource.class_eval do
      scope :child_scope, {}
    end
  end

  subject { ScopeResource }

  context 'defining scopes' do

    context '.scope?' do

      it 'returns false if the scope does not exist' do
        expect(subject.scope?(:fake_scope)).to eql(false)
      end

      it 'returns true if the scope exists' do
        expect(subject.scope?(:no_arg)).to eql(true)
      end

      it 'returns true for scopes defined on the parent class' do
        expect(
          ChildScopeResource.scope?(:no_arg)
        ).to be_true
      end

      it 'does not return true for scopes defined on a child class' do
        expect(subject.scope?(:child_scope)).to be_false
      end

    end

    context '.scope_definition' do

      it 'returns an instance of the proper class for default scopes' do
        expect(
          subject.scope_definition(:no_arg)
        ).to be_a(ApiResource::Scopes::DefaultScope)
      end

      it 'returns an instance of the proper class for optional args' do
        expect(
          subject.scope_definition(:opt_args)
        ).to be_a(ApiResource::Scopes::OptionalArgScope)
      end

      it 'returns an instance of the proper class for variable args' do
        expect(
          subject.scope_definition(:var_args)
        ).to be_a(ApiResource::Scopes::VariableArgScope)
      end

    end

  end

  context 'Using Scopes' do

    context '.add_scopes' do

      it 'returns a proper conditions object' do
        pending('need to implement scope objects')
      end

    # xit 'applies static scopes' do
    #   ScopeResource.expects(:no_arg).returns(ScopeResource)
    #   ScopeResource.add_scopes(no_arg: 1)
    # end

    # xit 'applies scopes with one argument' do
    #   ScopeResource.expects(:one_arg).with(5).returns(ScopeResource)
    #   ScopeResource.add_scopes(one_arg: {id: 5})
    # end

    # xit 'applies scopes with an array argument' do
    #   ScopeResource.expects(:one_array_arg).with([5]).returns(ScopeResource)
    #   ScopeResource.add_scopes(one_array_arg: {ids: [5]})
    # end

    # xit 'applies scopes with two arguments' do
    #   ScopeResource.expects(:two_args).with(7,9).returns(ScopeResource)
    #   ScopeResource.add_scopes(two_args: {page: 7, per_page: 9})
    # end

    # xit 'applies scopes with optional arguments when those arguments are supplied' do
    #   ScopeResource.expects(:opt_args).with(5).returns(ScopeResource)
    #   ScopeResource.add_scopes(opt_args: {arg1: 5})
    # end

    # xit "doesn't apply scopes with only optional arguments when there are no supplied args" do
    #   ScopeResource.expects(:opt_args).never
    #   ScopeResource.add_scopes(opt_args: {})
    # end

    # xit "applies scopes that have both optional and required args with only the required args if the optional args are not passed in" do
    #   ScopeResource.expects(:req_and_opt_args).with(5).returns(ScopeResource)
    #   ScopeResource.add_scopes(req_and_opt_args: {arg1: 5})
    # end

    # xit "applies scopes with variable arg lists" do
    #   ScopeResource.expects(:var_args).with([5,6,7]).returns(ScopeResource)
    #   ScopeResource.add_scopes(var_args: {ids: [5,6,7]})
    # end

    # xit "applies scopes with mixed arg lists" do
    #   ScopeResource.expects(:mix_args).with(4,[5,6,7]).returns(ScopeResource)
    #   ScopeResource.add_scopes(mix_args: {id: 4, vararg: [5,6,7]})
    # end

    end

  end

end