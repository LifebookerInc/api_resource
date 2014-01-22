module ApiResource
  module Formats

    autoload :FileUploadFormat, 'api_resource/formats/file_upload_format'
    autoload :JsonFormat, 'api_resource/formats/json_format'
    autoload :XmlFormat, 'api_resource/formats/xml_format'


    # Lookup the format class from a mime type reference symbol. Example:
    #
    #   ActiveResource::Formats[:xml]  # => ActiveResource::Formats::XmlFormat
    #   ActiveResource::Formats[:json] # => ActiveResource::Formats::JsonFormat
    def self.[](mime_type_reference)
      format_name = ActiveSupport::Inflector.camelize(mime_type_reference.to_s) + "Format"
      begin
        ApiResource::Formats.const_get(format_name)
      rescue NameError => e
        raise BadFormat.new("#{mime_type_reference} is not a valid format")
      end
    end

    class BadFormat < StandardError
    end
  end
end
