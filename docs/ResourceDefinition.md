# The Resource Definition

The Resource Definition is the way that the Server application communicates
the properties and scopes of its models to the Client application

## How do I set this up in my Server application?

Full documentation is available at {http://path/to/server/docs ApiResourceServer}

## Definition Components

### Attributes

Attributes are typically fields in the database, but can be declared using
`virtual_attribute` in the Server's model as well

#### Visibility

ApiResourceServer hooks into `attr_protected` and provides `attr_private` to
communicate visibility of different attributes


### Scopes

ApiResource also hooks into ActiveRecord's `scope` to communicate
the models in the Server applications' scopes

### Associations

ApiResource also hooks into ActiveRecord's `has_many`, `belongs_to` and
`has_one` associations to communicate the models in the Server applications'
associations

## Exposing the Resource Definition

The Server application is responsible for exposing the Resource Definition
to the Client application.  It should do so at
`GET /PLURALIZED_RESOURCE_NAME/new.json`


## Examples

See {http://path/to/server/docs ApiResourceServer} for more information
on declaring your attributes


## Final Resource Definition

    {
      attributes: {
        public: [
          ["birthday", Date],
          ["first_name", "string"],
          ["last_name", "string"]
        ],
        protected: [
          ["created_at", "time"],
          ["id", "integer"]
          ["updated_at", "time"]
        ]
      },
      associations : {
        belongs_to: {
          state: {}
        },
        has_many: {
          friends: {}
        }

      },
      scopes: {
        active: {},
        born_on: { date: :req }
      }

    }




