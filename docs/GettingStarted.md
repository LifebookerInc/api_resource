# Getting Started with ApiResource

## Creating a model in your Client application

All of your models will extend {ApiResource::Base}

    # This must be loaded explicitly or created in a directory that is
    # autoloaded

    # lib/resources/person.rb
    module Resources
      class Person < ApiResource::Base
      end
    end

## Adding a resource definition in your Server application

On the server-side, you will need to activate the resource

    # app/modeperson.rb
    class Person < ActiveRecord::Base

      # this gives Person access to the methods necessary
      # to create a resrouce definition
      include LifebookerCommon::Model::Resource

      # Example attributes
      #
      # :first_name, :last_name, :birthday

      # Example validation
      #
      validates :birthday,
        presence: true

    end

Read more about {file:docs/ResourceDefinition.md Resource Definitions}

## Adding basic routes and controller actions to your Server application

    # config/routes.rb
    resources :people

    # app/controllers/people_controller.rb
    class PeopleController < ApplicationController

      respond_to :json

      # GET /people/new
      def new
        respond_with(Person.resource_definition)
      end

      # GET /people
      def index
        respond_with(Person.all)
      end

      # GET /people/:id
      def show
        @person = Person.find(params[:id])
        respond_with(@person)
      end

      # POST /people
      def create
        @person = Person.create(params[:person])
        respond_with(@person)
      end

      # PUT /people/:id
      def update
        @person = Person.find(params[:id])
        @person.update_attributes(params[:person])
        respond_with(@person)
      end

      # DELETE /people/:id
      def destory
        @person = Person.find(params[:id])
        @person.destory
        respond_with(@person)
      end
    end

## Creating a new record in your Client application

ApiResource knows about your Server model's attributes through its
{file:docs/ResourceDefinition.md Resource Definition}, so you can just
set its attributes and call {#save}

It attempts to replicate the behaviors of ActiveRecord as closely as possible

    # in any part of your Client application
    @person = Resources::Person.new(first_name: 'Aaron', last_name: 'Burr')
    @person.save #=> true/false

    # if we have errors
    @person.errors #=> ActiveModel::Errors
    @person.errors.full_messages #=> ['Birthday is required.']

Read more about {file:docs/Persistance.md Persistance}

## Finding a single record in your Client application

    # raises ApiResource::ResourceNotFound if no Person is found on
    # the server and a 404 is returned
    #
    # GET /people/#{params[:id]}.json
    @person = Resource::Person.find(params[:id])

## Finding multiple records in your Client application

The query interface mimics ActiveRecord/Arel and reads scopes from the
{file:docs/ResourceDefinition.md Resource Definitions}

    # GET /people.json
    @people = Resource::Person.all # all people

    # GET /people.json?first_name=Aaron
    @people = Resource::Person.where(first_name: 'Aaron')
    #=> ApiResource::ScopeCondition - Loaded on demand when you start
    # iterating through the resource (e.g. @people.each {...})

For more information see {file:docs/Retrieval.md#scopes Scopes}

## Updating a record

To update, you just find one or more records and call
{ApiResource::Base#update_attributes #update_attributes} on each record

    @person = Resource::Person.find(1)
    @person.update_attributes(
      first_name: 'Joseph',
      last_name: 'Stalin',
      birthday: nil
    )
    # => true/false

    @person.errors.full_messages # => ['Birthday is required.']

## Deleting a record

To delete, just find a record and call {ApiResource::Base#destroy #destroy}
on it

    @person = Resource::Person.find(1)
    @person.destroy # => true/false