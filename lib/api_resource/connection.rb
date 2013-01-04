require 'active_support/core_ext/benchmark'
require 'rest_client'
require 'net/https'
require 'date'
require 'time'
require 'uri'

module ApiResource
  # Class to handle connections to remote web services.
  # This class is used by ActiveResource::Base to interface with REST
  # services.
  class Connection

    HTTP_FORMAT_HEADER_NAMES = {  
      :get => 'Accept',
      :put => 'Content-Type',
      :post => 'Content-Type',
      :delete => 'Accept',
      :head => 'Accept'
    }

    attr_reader :site, :user, :password, :auth_type, :timeout, :proxy, :ssl_options
    attr_accessor :format, :headers

    class << self
      def requests
        @@requests ||= []
      end
    end

    # The +site+ parameter is required and will set the +site+
    # attribute to the URI for the remote resource service.
    def initialize(site, format = ApiResource::Formats::JsonFormat, headers)
      raise ArgumentError, 'Missing site URI' unless site
      @user = @password = nil
      @uri_parser = URI.const_defined?(:Parser) ? URI::Parser.new : URI
      self.site = site
      self.format = format
      self.headers = headers
    end

    # Set URI for remote service.
    def site=(site)
      @site = site.is_a?(URI) ? site : @uri_parser.parse(site)
      @user = @uri_parser.unescape(@site.user) if @site.user
      @password = @uri_parser.unescape(@site.password) if @site.password
    end

    # Sets the number of seconds after which HTTP requests to the remote service should time out.
    def timeout=(timeout)
      @timeout = timeout
    end
    
    def get(path, headers = self.headers)
      # our site and headers for this request
      site = self.site.merge(path)
      headers = build_request_headers(headers, :get, site)

      self.with_caching(path, headers) do
        format.decode(request(:get, path, headers))
      end
    end
    
    def delete(path, headers = self.headers)
      request(:delete, path, build_request_headers(headers, :delete, self.site.merge(path)))
      return true
    end
    
    def head(path, headers = self.headers)
      request(:head, path, build_request_headers(headers, :head, self.site.merge(path)))
    end
    
    # make a put request
    def put(path, body = {}, headers = self.headers)
      format.decode(
        request(
          :put, 
          path, 
          body, 
          build_request_headers(headers, :put, self.site.merge(path))
        )
      )
    end
    
    # make a post request
    def post(path, body = {}, headers = self.headers)
      format.decode(
        request(
          :post, 
          path, 
          body, 
          build_request_headers(headers, :post, self.site.merge(path))
        )
      )
    end

    protected

    def cache_key(path, headers)
      key = Digest::MD5.hexdigest([path, headers].to_s)
      return "a-#{key}-#{ApiResource::Base.ttl}"
    end

    def with_caching(path, data = {}, &block)
      if ApiResource::Base.ttl.to_f > 0.0
        key = self.cache_key(path, data)
        ApiResource.cache.fetch(key, :expires_in => ApiResource::Base.ttl) do
          yield
        end
      else
        yield
      end
    end

    private
      # Makes a request to the remote service.
      def request(method, path, *arguments)
        handle_response(path) do
          ActiveSupport::Notifications.instrument("request.api_resource") do |payload|
            
            # debug logging
            ApiResource.logger.info("#{method.to_s.upcase} #{site.scheme}://#{site.host}:#{site.port}#{path}")
            payload[:method]      = method
            payload[:request_uri] = "#{site.scheme}://#{site.host}:#{site.port}#{path}"
            payload[:result]      = http(path).send(method, *arguments)
          end
        end
      end

      # Handles response and error codes from the remote service.
      def handle_response(path, &block)
        begin
          result = yield
        rescue RestClient::RequestTimeout
          raise ApiResource::RequestTimeout.new("Request Time Out - Accessing #{path}}")
        rescue Exception => error
          if error.respond_to?(:http_code)
            ApiResource.logger.error("#{self} accessing #{path}")
            ApiResource.logger.error(error.message)
            result = error.response
          else
            raise ApiResource::ConnectionError.new(nil, :message => "Unknown error #{error}")
          end
        end
        return propogate_response_or_error(result, result.code)
      end
      
      def propogate_response_or_error(response, code)
        case code.to_i
          when 301,302
            raise ApiResource::Redirection.new(response)
          when 200..400
            response.body
          when 400
            raise ApiResource::BadRequest.new(response)
          when 401
            raise ApiResource::UnauthorizedAccess.new(response)
          when 403
            raise ApiResource::ForbiddenAccess.new(response)
          when 404
            raise ApiResource::ResourceNotFound.new(response)
          when 405
            raise ApiResource::MethodNotAllowed.new(response)
          when 406
            raise ApiResource::NotAccepatable.new(response)
          when 409
            raise ApiResource::ResourceNotFound.new(response)
          when 410
            raise ApiResource::ResourceGone.new(response)
          when 422
            raise ApiResource::UnprocessableEntity.new(response)
          when 401..499
            raise ApiResource::ClientError.new(response)
          when 500..600
            raise ApiResource::ServerError.new(response)
          else
            raise ApiResource::ConnectionError.new(response, :message => "Unknown response code: #{code}")
        end
      end
      
      # Creates new Net::HTTP instance for communication with the
      # remote service and resources.
      def http(path)
        unless path =~ /\./
          path += ".#{self.format.extension}"
        end
        RestClient::Resource.new("#{site.scheme}://#{site.host}:#{site.port}#{path}", {:timeout => ApiResource::Base.timeout, :open_timeout => ApiResource::Base.open_timeout})
      end
      
      def build_request_headers(headers, verb, uri)
        http_format_header(verb).update(headers)
      end
      
      def http_format_header(verb)
        {}.tap do |ret|
          ret[HTTP_FORMAT_HEADER_NAMES[verb]] = format.mime_type
        end
      end
  end
end
