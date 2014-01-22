require 'active_support/json'
require 'json'

module ApiResource
  module Formats


    #
    # @module FileUploadFormat
    #
    # Class to handle posting of multipart data to HTTPClient
    #
    module FileUploadFormat
      extend self

      #
      # The extension for the request
      #
      # @return [String]
      #
      def extension
        "json"
      end

      #
      # The mime_type header for the request
      #
      # @return [String]
      #
      def mime_type
        "multipart/form-data"
      end

      #
      # Implementation of {#encode} - encodes data to POST
      # to the server
      #
      # @return [Hash]
      #
      def encode(hash, options = nil)
        ret = {}
        hash.each_pair do |k,v|
          ret[k] = self.encode_value(v)
        end
        ret
      end

      #
      # Implementation of {#decode} - decodes data back from the server
      # We expect the data to be JSON-formatted
      #
      # @return [Hash]
      #
      def decode(json)
        JSON.parse(json)
      end

      protected

      def encode_value(val)
        case val
          when Hash
            self.encode(val)
          when Array
            val.collect{|v| self.encode_value(v)}
          when ActionDispatch::Http::UploadedFile
            val.tempfile
          else
            val
        end
      end

    end
  end
end