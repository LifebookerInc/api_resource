# Retrieving Records in ApiResource


## Finding by id

The simplest way to retrieve a record is by its ID

    Resource::Person.find(1)
    # GET /people/1.json

## Simple conditions

To add simple query params, you can just use the `.where` method

    Resource::Person.where(first_name: 'Aaron').all
    # GET /people.json?first_name=Aaron

## Scopes

Scopes must be activated in the Server application and are then read by
the client application via the
{file:docs/ResourceDefinition.md Resource Definition}.

### Activating a scope in the Server application

    # app/models/person.rb
    class Person < ActiveRecord::Base

      include LifebookerCommon::Model::Resource

      scope :birthday_on, -> date {
       where(birthday: date)
      }

      scope :aaron, -> {
        where(name: 'Aaron')
      }

    end

### Using a scope in the Client application

    # GET /people.json?birthday_on[date]=2014-01-01
    @people = Resource::Person.birthday_on(Date.parse('2014-01-01'))

    @people.each do |person|
      ...
    end

Scopes can be chained together

    # GET /people.json?birthday_on[date]=2014-01-01&aaron=1
    @people = Resource::Person
      .birthday_on(Date.parse('2014-01-01'))
      .aaron

    @people.each do |person|
      ...
    end

### Applying scopes in the Client application

ApiResource::Base gives us the ability to apply scopes that are valid
according to the {file:docs/ResourceDefinition.md Resource Definition}
directly from params that are passed in

    # In the Client application
    class PeopleController < ApplicationController

      def index
        @people = Resource::Person.add_scopes(params)
      end

    end

This reads the params supplied to the controller to see if there are any
valid scopes and then applies them.  These scopes follow the same rules
as the ones that are sent to the server

#### Sequence

1. Client supplies params to our client app

        # curl http://clienthost/people.html?birthday_on[date]=2014-01-01

1. Client controller parses params, passes them to {ApiResource.add_scopes}
  and creates a ScopeCondition to generate params to the server

1. Resource::Person makes a request to the Server application.  This request
  has the same parameters as what was passed in to the client application
  assuming those parameters were valid for a scope

        # GET http://serverhost/people.json?birthday_on[date]=2014-01-01

1. Server application returns the data as JSON and Resource::Person
  instantiates its records for use in the Client application

### Automatically generated scopes

`api_resource_server` and {ApiResource::Base} automatically provide several
scopes for all descendants of ActiveRecord::Base and ApiResource::Base
respectively

#### IDs

You can supply an array of ids to a resource to scope by only resources in
that set of ids

    # in the Client application
    Resource::Person.add_scopes(ids: [1, 2, 3])
    # => GET /people.json?ids[]=1&ids[]=2&ids[]=3

#### Type

In order to limit your scope to a subclass of a class that users Single Table
Inheritance, you can supply the type

    # in the Server application
    class Carpenter < Person
    end

    # in the Client application
    Resource::Person.type('Carpenter')
    # => GET /people.json?type=Carpenter

    # back in the Server application Person.add_scopes
    # converts

    Person.all

    # into

    Carpenter.all

#### Page and PerPage

In order to paginate, you can pass page and per_page scopes into your
ApiResource::Base subclass

    Resource::Person.per_page(20).page(1)

    # or

    Resource::Person.add_scopes(per_page: 20, page: 1)

    # either of these produce
    GET /people.json?page=1&per_page=20

In the Server application `add_scopes` will take care of applying
the pagination using its integration with
{https://github.com/mislav/will_paginate will_paginate}

In addition, the Server application will include a header denoting
the number of records in the set so that
{https://github.com/mislav/will_paginate will_paginate} can
render its page helpers on the client side

*Note* that in order to enable this feature the Server application
*must* use `respond_to`

    # in a controller in the Client application
    @people = Resource::Person.add_scopes(
      params.merge(page: 2, per_page: 20)
    )

    # in a view in the Client application
    - @people.each do |person|
      %tr
        %td ...
    # renders the pagination links
    = will_paginate(@people)

### Types of scopes

1. Static scopes

        # Server code
        scope :x, where(x: 'Val')
        OR
        scope :x, -> { where(x: 'Val') }

        # Produces request from client
        Resource::Person.x
        # ?x=1

1. Scopes with required parameters

        # Server code
        scope :birthday_between, -> start, end {
          where("birthday_between ? AND ?", start, end)
        }

        # Produces request from the client
        @people = Resource::Person.birthday_between(
          start: Date.today,
          end: Date.tomorrow
        )
        # ?birthday_between[start]=2014-01-01&birthday_between[end]=2014-01-02

1. Scopes with varargs

        # server code
        scope :first_name, -> *names {
          where(first_name: names)
        }

      # Produces request from the client
      @people = Resource::Person.first_name('Bill', 'Sue')
      # ?first_name[]=Bill&first_name[]=Sue

## Including associated data

Oftentimes we will need data from two resources, which would produce n+1 API
calls unless we sideload our data

### Concept

If, for example we loaded a list of 50 People, but needed their State data we
might have to make 50 requests to the State API endpoint

### Server application

    # in app/models/person.rb
    class Person < ActiveRecord::Base

      belongs_to :state

      # Attributes
      #
      # :first_name, :last_name, :state_id

    end

    # in app/models/state.rb
    class State < ActiveRecord::Base
      # Attributes
      #
      # :name
    end

    # in app/controllers/people_controller.rb
    def index
      respond_with(Person.add_scopes(params))
    end

    # in app/controllers/states_controller.rb
    def index
      respond_with(State.add_scopes(params))
    end

### Client application

    # in lib/resource/state.rb
    module Resource
      class State < ApiResource::Base
      end
    end

    # in lib/resource/person.rb
    module Resource
      class Person < ApiResource::Base
      end
    end

    # in a controller
    @people = Resource::Person.includes(:state)

    # this results in
    #
    # GET /people.json
    #
    # and
    #
    # GET /states.json?ids[]=person1.state_id&ids[]=person2.state_id ...


{ApiResource::Base} knows how to include data from any association where
ids are embedded in the response of the base object and the association
is present in the {file:docs/ResourceDefinition.md Resource Definition}
