require 'active_support/json'
require 'json'
module ApiResource
  module Formats
    module JsonFormat
      extend self

      def extension
        "json"
      end

      def mime_type
        "application/json"
      end

      def encode(hash, options = nil)
        JSON.dump(hash, options)
      end

      def decode(json)
        if json.strip.blank?
          return {}
        else
          JSON.parse(json)
        end
      end
    end
  end
end
