# Serialization in ApiResource

## Sending Data to Server (JSON)

Data is Serialized using singular resource name as a key, and the attributes as the value.

    # POST /people.json

    # POST body
    {
      person: {
        first_name: "Aaron",
        last_name: "Burr",
        birthdate: "1755-02-05"
      }
    }

## Retrieving Data From Server

ApiResource expects resources to be at the root of the JSON or XML document
returned

    # GET /people/1.json

    # Response
    {
      first_name: 'Aaron',
      last_name: 'Burr',
      birthdate: '1756-02-06'
    }

    # GET /people.json

    # Response
    [
      {
        first_name: 'Aaron',
        last_name: 'Burr',
        birthdate: '1756-02-06'
      }
    ]

## Setting the Serializer Format

ApiResource ships with two major Formats: {ApiResource::Formats::JsonFormat}
and {ApiResource::Formats::XmlFormat}

The default format is `:json`

You can configure your format:

    ApiResource::Base.format = ApiResource::Formats::JsonFormat

    # OR

    ApiResource::Base.format = :xml