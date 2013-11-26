require 'spec_helper'

module ApiResource

  module Conditions

    describe PaginationCondition do

      context '.paginate' do

        it 'returns an object that knows it is paginated from the base
          class' do
          paginated = TestResource.paginate(page: 1, per_page: 10).active
          expect(paginated).to be_paginated
        end

        it 'returns an object that knows it is paginated from a scope' do
          paginated = TestResource.active.paginate(
            page: 1,
            per_page: 10
          )
          expect(paginated).to be_paginated
        end

      end

      context '#current_page' do

        it 'knows its page number' do
          paginated = TestResource.paginate(page: 1, per_page: 10).active
          expect(paginated.current_page).to be 1
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
          expect(paginated.total_pages).to be 9
        end

      end

    end

  end

end