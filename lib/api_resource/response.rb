module ApiResource
  class Response

    attr_accessor :body
    attr_reader :headers

    # explicit delegate for things we define
    delegate(
      :as_json,
      :blank?,
      :inspect,
      :to_s,
      to: :body
    )

    #
    # Constructor
    #
    # @param  response [HttpClient::Response]
    # @param  format [ApiResource::Format] Decoder
    #
    def initialize(response)
      @body = self.parse_body(response)
      @headers = response.try(:headers) || {}
    end

    #
    # We typically treat the response as just a wrapper for an
    # Array or a Hash and use is_a? to determine what kind of response
    # we have.  So to keep that consistent, #is_a? returns true if the
    # body is a descendant of the class as well
    #
    # @param  klass [Class]
    #
    # @return [Boolean]
    def is_a?(klass)
      super || @body.is_a?(klass)
    end

    #
    # Implementation of marshal_dump
    #
    # @return [Array<Hash>] The data to dump
    def marshal_dump
      [@body, @headers]
    end

    #
    # Implementation of marshal load
    # @param  args [Array] Array of dumped data
    #
    # @return [Response] New instance
    def marshal_load(args)
      @body, @headers = args
      self
    end


    #
    # Return ourself cloned with the body wrapped as an array
    #
    # @example
    #   resp = ApiResource::Response.new(response, format)
    #   resp.body # => {'a' => 'b'}
    #
    #   array = Array.wrap(resp)
    #   array.body # => [{'a' => 'b'}]
    #
    #   array.response == resp.response # true!
    #
    # @return [ApiResource::Response]
    def to_ary
      klone = self.dup
      klone.body = Array.wrap(self.body)
      klone
    end

    protected

    #
    # Proxy method missing to the body
    #
    # @param  meth [Symbol] Method called
    # @param  *args [Array<Mixed>] Args passed
    # @param  &block [Proc] Block passed
    #
    # @return [Mixed]
    def method_missing(meth, *args, &block)
      @body.__send__(meth, *args, &block)
    end

    #
    # Handle parsing of the body.  Returns a blank Hash if
    # no body is present
    #
    # @param  response [HttpClient::Response]
    #
    # @return [Hash, Array<Hash>] Parsed response
    def parse_body(response)
      if response.try(:body).present?
        return ApiResource.format.decode(response.body)
      else
        return {}
      end
    end

  end
end