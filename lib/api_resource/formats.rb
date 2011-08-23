module ApiResource
  module Formats
    autoload :XmlFormat, 'api_resource/formats/xml_format'
    autoload :JsonFormat, 'api_resource/formats/json_format'

    # Lookup the format class from a mime type reference symbol. Example:
    #
    #   ActiveResource::Formats[:xml]  # => ActiveResource::Formats::XmlFormat
    #   ActiveResource::Formats[:json] # => ActiveResource::Formats::JsonFormat
    def self.[](mime_type_reference)
      ApiResource::Formats.const_get(ActiveSupport::Inflector.camelize(mime_type_reference.to_s) + "Format")
    end
  end
end
