# Relationships

ApiResource mimics ActiveRecord's relationships, but loads the data via an
API or instantiates a record when data is nested

## There are 3 ways to include associated data in a response for APIResource

The proper approach will depend on the specifics of the Server and Client
applications.  For example, if an associated resource is used just about
every time the parent is retrieved, it makes sense to nest it.

In general, nesting increases the overall complexity of the Server app and
slows it down though, so it should be used with caution

Models in the Server application

    class Person < ActiveRecord::Base
      belongs_to :state
      has_many :weapons, through: :person_weapons
    end

    class PersonWeapon < ActiveRecord::Base
      belongs_to :weapon
      belongs_to :person
    end

    class Weapon < ActiveRecord::Base
      scope :sharp, -> { where(sharp: true) }
    end

    class State < ActiveRecord::Base
    end

The Server application would need to have Controllers defined to expose these
models and their {file:docs/ResourceDefinition.md Resource Definitions}.  For
an example of that visit {file:docs/GettingStarted.md Getting Started}


1. Include the data nested in the response

        # GET /people/1.json

        # Response
        {
          first_name: 'Aaron',
          last_name: 'Burr',
          weapons: [
            { id: 1, name: 'Ax', sharp: true },
            { id: 2, name: 'Pistol', sharp: false }
          ],
          state: { id: 10, name: 'New York' }
        }

        # in the Client application
        person = Resource::Person.find(1)
        person.state.name # => 'New York'
        person.weapons.length # => 2

        # no additional HTTP calls are made

1. Include a link to the data in the response

        # GET /people/1.json

        # Response
        {
          first_name: 'Aaron',
          last_name: 'Burr',
          weapons: [ { service_uri: '/people/1/weapons' } ],
          state: { service_uri: '/states/10' }
        }

        # in the Client application
        person = Resource::Person.find(1)
        person.state.name # => 'New York'
        person.weapons.length # => 2

        # 2 additional HTTP calls are made
        # (1 to each :service_uri provided)

1. Include the ids for the associated objects in the response

        # GET /people/1.json

        # Response
        {
          first_name: 'Aaron',
          last_name: 'Burr',
          weapon_ids: [ 1, 2 ],
          state_id: 10
        }

        # in the Client application
        person = Resource::Person.find(1)
        person.state.name # => 'New York'
        person.weapons.length # => 2

        # 2 additional HTTP calls are made
        # GET /weapons.json?ids[]=1&ids[]=2
        # and
        # GET /states/10.json


## Applying a scope to a relationship

Any scope on the relationship model can be applied to the relationship and
will be passed on to the server

*Note:* This does not work with embedded data because it has already
be loaded with the parent resource


    @person = Resource::Person.find(1)

    # GET /people/1/weapons.json
    @person.weapons
    # => [ Resource::Weapon(id: 1, name: 'Ax', sharp: true), Resource::Weapon(id: 2, name: 'Pistol', sharp: false) ]

    # GET /people/1/weapons.json?sharp=true
    @person.weapons.sharp
    # => [ Resource::Weapon(id: 1, name: 'Ax', sharp: true) ]

## Saving associated records

By default, ApiResource assumes that any modifications to individual records
in an Association will be saved directly via that record

ApiResource::Base does provide the option to `:include_associations` on save
to mass-update records.  This includes the data with the parent record's save
call.

    @person = Resource::Person.find(1)

    @person.state.name = 'I renamed New York'
    @person.save(include_associations: [:state])
    # PUT /people.json { state: { name: 'I renamed New York', id: 10 } }