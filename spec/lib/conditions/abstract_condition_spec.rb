require 'spec_helper'

describe ApiResource::Conditions::AbstractCondition do

	subject {
		ApiResource::Conditions::AbstractCondition.new(
			TestResource
		)
	}

	context 'Proxying methods' do

		it 'returns defaults if it the owner is not set' do
			expect(subject.conditions).to eql({})
			expect(subject).to_not be_paginated
			expect(subject).to_not be_eager_load
			expect(subject.per_page).to eql(1)
		end

		it 'proxies methods to the owner if it is set' do
			subject.set_owner(mock(
				conditions: { a: :b},
				paginated?: true,
				per_page: 2
			))
			expect(subject.conditions).to eql({ a: :b })
			expect(subject).to be_paginated
			expect(subject.per_page).to eql(2)
		end

	end

	context 'Responding to scopes' do

		before(:all) do
			TestResource.class_eval do
				scope :ac_scope1, { arg1: :req, arg2: :req }
				scope :ac_scope2, { arg3: :req }
			end
		end

		it 'responds to the scope methods of the basis class' do
			expect(subject).to respond_to(:ac_scope1)
			expect(subject).to respond_to(:ac_scope2)
		end

		it 'returns a new scope object with the owner set when chaining' do
			result = subject.ac_scope1(1, 2)
			expect(result.owner).to eql(subject)
			expect(result.conditions).to eql(
				{ 'ac_scope1'=> { 'arg1' => 1, 'arg2' => 2 } }
			)
		end

		it 'allows chaining with multiple scopes' do
			result = subject.ac_scope1(1,2).ac_scope2(3)
			expect(result.owner.owner).to eql(subject)
			expect(result.conditions).to eql(
				{
					'ac_scope1' => { 'arg1' => 1, 'arg2' => 2 },
					'ac_scope2' => { 'arg3' => 3 }
				}
			)
		end

	end

	context 'Loading data' do

		it 'loads via a finder object when calling internal_object' do
			ApiResource::Finders::MultiObjectFinder
				.any_instance
				.expects(:internal_object)
				.returns([1, 2, 3])

			expect(subject.internal_object).to eql([1,2,3])
		end

		it 'loads via a finder object when calling an unknown method' do
			ApiResource::Finders::MultiObjectFinder
				.any_instance
				.expects(:internal_object)
				.returns([1, 2, 3])

			expect(subject.push(4)).to eql([1, 2, 3, 4])
		end

		it 'delegates loading to the basis when calling find' do
			TestResource.expects(:find_with_condition)
				.with(subject, 1, 2, 3)
				.returns([1,2,3])

			expect(subject.find(1,2,3)).to eql([1,2,3])
		end

	end

	context 'Decorators' do

		it 'returns a caching decorator object' do
			result = subject.expires_in(5.minutes)
			expect(result).to be_a(ApiResource::Decorators::CachingDecorator)
			expect(result.ttl).to eql(5.minutes)
		end

		it 'returns an async decorator and loads in the background' do
			ApiResource::Finders::MultiObjectFinder
				.any_instance
				.expects(:internal_object)
				.returns([1, 2, 3])

			result = subject.async do |results|
				results.map { |i| i + 1 }
			end

			expect(result.value).to eql([2, 3, 4])
		end

		it 'can chain async onto caching' do
			ApiResource::Finders::MultiObjectFinder
				.any_instance
				.expects(:internal_object)
				.returns([1, 2, 3])

			result = subject.expires_in(5.minutes).async

			expect(result.value).to eql([1,2,3])
		end

	end

end