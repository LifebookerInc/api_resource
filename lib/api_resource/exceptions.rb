module ApiResource

  #
  # Superclass for all errors raised by ApiResource to enable
  # them to be handled more easily
  #
  # @author [ejlangev]
  #
  class Error < StandardError
  end

  class ConnectionError < StandardError # :nodoc:

    cattr_accessor :http_code

    attr_reader :response

    def initialize(response, options = {})
      @response = response
      @message  = options[:message]
      @path     = options[:path]
    end

    def to_s
      message = "Failed."

      if response.respond_to?(:code)
        message << "  Response code = #{response.code}."
      end

      if response.respond_to?(:body)
        begin
          body = JSON.parse(response.body).pretty_inspect
        rescue
          body = "INVALID JSON: #{response.body}"
        end
        message << "\nResponse message = #{body}."
      end

      message << "\n#{@message}"
      message << "\n#{@path}"
    end

    def http_code
      self.class.http_code
    end

  end

  # Raised when a Timeout::Error occurs.
  class RequestTimeout < ConnectionError
    def initialize(message)
      @message = message
    end
    def to_s; @message ;end
  end

  # Raised when a OpenSSL::SSL::SSLError occurs.
  class SSLError < ConnectionError
    def initialize(message)
      @message = message
    end
    def to_s; @message ;end
  end

  # 3xx Redirection
  class Redirection < ConnectionError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
  end

  # 4xx Client Error
  class ClientError < ConnectionError; end # :nodoc:

  # 400 Bad Request
  class BadRequest < ClientError; self.http_code = 400; end # :nodoc

  # 401 Unauthorized
  class UnauthorizedAccess < ClientError; self.http_code = 401; end # :nodoc

  # 403 Forbidden
  class ForbiddenAccess < ClientError; self.http_code = 403; end # :nodoc

  # 404 Not Found
  class ResourceNotFound < ClientError; self.http_code = 404; end # :nodoc:

  # 406 Not Acceptable
  class NotAcceptable < ClientError; self.http_code = 406; end

  # 409 Conflict
  class ResourceConflict < ClientError; self.http_code = 409; end # :nodoc:

  # 410 Gone
  class ResourceGone < ClientError; self.http_code = 410; end # :nodoc:

  class UnprocessableEntity < ClientError; self.http_code = 422; end

  # 5xx Server Error
  class ServerError < ConnectionError;  self.http_code = 400; end # :nodoc:

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:

    self.http_code = 405

    def allowed_methods
      @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
    end
  end
end
