require 'spec_helper'

module ApiResource

  module Conditions

    describe PaginationCondition do

      before(:all) do
        TestResource.class_eval do
          scope :pc_scope, {}
        end
      end

      context '.paginate' do

        it 'returns an object that knows it is paginated from the base
          class' do
          paginated = TestResource.paginate(page: 1, per_page: 10).pc_scope
          expect(paginated).to be_paginated
        end

        it 'returns an object that knows it is paginated from a scope' do
          paginated = TestResource.pc_scope.paginate(
            page: 1,
            per_page: 10
          )
          expect(paginated).to be_paginated
        end

      end

      context '#current_page' do

        it 'knows its page number' do
          paginated = TestResource.paginate(page: 2, per_page: 10).pc_scope
          expect(paginated.current_page).to be 2
        end

      end

      context '#offset' do

        it 'passes along the headers for the total number of entries' do
          paginated = TestResource.paginate(
            page: 2,
            per_page: 10
          )
          expect(paginated.offset).to be 10
        end

      end

      context '#per_page' do

        it 'knows its number per page' do
          paginated = TestResource.paginate(
            page: 2,
            per_page: 100
          )
          expect(paginated.per_page).to be 100
        end

      end

      context '#total_entries' do

        it 'passes along the headers for the total number of entries' do
          pending('Need finders working to finish this spec')
          paginated = TestResource.paginate(
            page: 1,
            per_page: 10
          )
          expect(paginated.total_entries).to be 100
        end

      end

      context '#total_pages' do

        it 'calculates the number of pages' do
          paginated = TestResource.paginate(
            page: 1,
            per_page: 12
          )
          paginated.expects(:total_entries).returns(106)

          expect(paginated.total_pages).to be 9
        end

      end

    end

  end

end