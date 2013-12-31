require 'spec_helper'

describe ApiResource::Scopes do

  before(:all) do
    ScopeResource.class_eval do
      scope :no_arg, {}
      scope :one_arg, {id: :req}
      scope :one_array_arg, {ids: :req}
      scope :two_args, {page: :req, per_page: :req}
      scope :opt_args, {arg1: :opt}
      scope :req_and_opt_args, {arg1: :req, arg2: :opt}
      scope :var_args, {ids: :rest}
      scope :mix_args, {id: :req, vararg: :rest}
      scope :date_scope, {start_date: :req, end_date: :req}
    end
  end

  context "Constructing arguments" do

    it "should be able to query scopes on the current model" do
      ScopeResource.no_arg.to_query.should eql(
        "no_arg=true"
      )
      ScopeResource.one_arg(5).to_query.should eql(
        "one_arg[id]=5"
      )
      ScopeResource.one_array_arg([3, 5]).to_query.should eql(
        "one_array_arg[ids][]=3&one_array_arg[ids][]=5"
      )
      ScopeResource.two_args(1, 20).to_query.should eql(
        "two_args[page]=1&two_args[per_page]=20"
      )
      $DEB = true
      ScopeResource.opt_args.to_query.should eql(
        "opt_args=true"
      )
      ScopeResource.opt_args(3).to_query.should eql(
        "opt_args[arg1]=3"
      )
      ScopeResource.var_args(1, 2).to_query.should eql(
        "var_args[ids][]=1&var_args[ids][]=2"
      )
      args = ["a", {opt1: 1}, {opt2: 2}]
      ScopeResource.mix_args(*args).to_query.should eql(
        "mix_args[id]=a&mix_args[vararg][][opt1]=1&mix_args[vararg][][opt2]=2"
      )
    end
  end

  context '#add_scopes' do

    it 'applies static scopes' do
      ScopeResource.expects(:no_arg).returns(ScopeResource)
      ScopeResource.add_scopes(no_arg: 1)
    end

    it 'applies scopes with one argument' do
      ScopeResource.expects(:one_arg).with(5).returns(ScopeResource)
      ScopeResource.add_scopes(one_arg: {id: 5})
    end

    it 'does not apply scopes with a blank argument' do
      ScopeResource.expects(:one_arg).never
      ScopeResource.add_scopes(one_arg: {id: ""})
      ScopeResource.add_scopes(one_arg: {id: nil})
    end

    it 'does not apply scopes when a parameter is missing' do
      ScopeResource.expects(:two_args).never
      ScopeResource.add_scopes(two_args: { page: 1 })
      ScopeResource.add_scopes(two_args: { per_page: 1 })
    end

    it 'applies scopes with an array argument' do
      ScopeResource.expects(:one_array_arg).with([5]).returns(ScopeResource)
      ScopeResource.add_scopes(one_array_arg: {ids: [5]})
    end

    it 'applies scopes with two arguments' do
      ScopeResource.expects(:two_args).with(7,9).returns(ScopeResource)
      ScopeResource.add_scopes(two_args: {page: 7, per_page: 9})
    end

    it 'applies scopes with optional arguments when those arguments are supplied' do
      ScopeResource.expects(:opt_args).with(5).returns(ScopeResource)
      ScopeResource.add_scopes(opt_args: {arg1: 5})
    end

    it "doesn't apply scopes with only optional arguments when there are no supplied args" do
      ScopeResource.expects(:opt_args).never
      ScopeResource.add_scopes(opt_args: {})
    end

    it "applies scopes that have both optional and required args with only the required args if the optional args are not passed in" do
      ScopeResource.expects(:req_and_opt_args).with(5).returns(ScopeResource)
      ScopeResource.add_scopes(req_and_opt_args: {arg1: 5})
    end

    it "applies scopes with variable arg lists" do
      ScopeResource.expects(:var_args).with([5,6,7]).returns(ScopeResource)
      ScopeResource.add_scopes(var_args: {ids: [5,6,7]})
    end

    it "applies scopes with mixed arg lists" do
      ScopeResource.expects(:mix_args).with(4,[5,6,7]).returns(ScopeResource)
      ScopeResource.add_scopes(mix_args: {id: 4, vararg: [5,6,7]})
    end

    it 'parses dates if the parameters are correctly named' do
      ScopeResource.expects(:date_scope)
        .with(instance_of(Date), instance_of(Date))
        .returns(ScopeResource)

      ScopeResource.add_scopes({
        date_scope: { start_date: 'May 6, 2013', end_date: 'June 8, 2014' }
      })
    end

  end

end