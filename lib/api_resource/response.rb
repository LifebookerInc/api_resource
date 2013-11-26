module ApiResource
  class Response

    attr_accessor :body
    attr_reader :response

    # explicit delegate for things we define
    delegate(
      :as_json,
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
    def initialize(response, format)
      @response = response
      @body = format.decode(response.body)
    end

    #
    # Reader for the headers from our response
    #
    # @return [Hash] Headers hash
    def headers
      @response.try(:headers)
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

  end
end