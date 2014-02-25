# Attributes

Attributes are read from the Server application's
{file:docs/ResourceDefinition.md Resource Definition}.

## Visibility

### Public

Can read and write, data is sent to the server if it has changed

### Protected

Can read only.  Cannot set or mass-assign

    # Resource definition
    # {
    #   ...
    #   protected : [
    #     ['updated_at', 'time']
    #   ]
    #   ...
    # }

    Resource::Person.new(updated_at: Time.now) # => Raises error
    resource = Resource::Person.new
    resource.updated_at = Time.now #=> Raises error

### Private

Field is not even definted or included in the
{file:docs/ResourceDefinition.md Resource Definition}.  For more
info see {http://path/to/server/docs ApiResourceServer ApiResource Server}


## Typecasting

ApiResource supports the following types:

1. Array
1. Boolean
1. Date
1. Float
1. Integer
1. String
1. Time

Attributes are given a type in the
{file:docs/ResourceDefinition.md Resource Definition}.  For more
info see {http://path/to/server/docs ApiResourceServer ApiResource Server}

## Dirty Tracking

ApiResource::Base includes ActiveModel::Dirty and uses Dirty Tracking to
determine which attributes to send to the server on save.  Only attributes
that have changed are sent to the server.

    person = Resource::Person.find(1)
    person.attributes
    # => { first_name: 'Aaron', last_name: 'Burr', ...}
    person.last_name = 'Copeland'

    person.save
    # PUT /people/1.json { person: { last_name: 'Copeland' } }