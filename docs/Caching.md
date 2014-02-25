# Caching

Caching is implemented at the connection level and caches the
respone body and headers of any GET request made while caching
is active for the period specified

## Where is it cached?

By default we use Rails.cache

    # Configure the cache to use a MemoryStore
    ApiResource::Base.cache = ActiveSupport::Cache::MemoryStore.new


## Activating caching globally

This will cache all GET requests for 30 seconds

    ApiResource::Base.ttl = 30.seconds

## Activating caching for a given find call

    Resource::Person.born_on(Date.today).expires_in(30.seconds).all


## Cache expiration

    Resource::Person.born_on(Date.today).expires_in(30.seconds).all

    # no HTTP request here
    Resource::Person.born_on(Date.today).expires_in(30.seconds).all

    sleep(30)

    # cache has expired - new HTTP Request
    Resource::Person.born_on(Date.today).expires_in(30.seconds).all


## Differing cache times for the same URL

Cache requests are specific to the cache interval specified.  For example,
if a find with a 60 second TTL and then another with a 30 second TTL will
make two calls


