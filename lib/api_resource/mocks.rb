require 'api_resource'

module ApiResource
  
  module Mocks
  
    @@endpoints = {}
    @@path = nil

    # A simple interface class to change the new connection to look like the 
    # old activeresource connection
    class Interface
      
      def initialize(path)
        @path = path
      end
      
      def get(*args, &block)
        Connection.send(:get, @path, *args, &block)
      end
      def post(*args, &block)
        Connection.send(:post, @path, *args, &block)
      end
      def put(*args, &block)
        Connection.send(:put, @path, *args, &block)
      end
      def delete(*args, &block)
        Connection.send(:delete, @path, *args, &block)
      end
      def head(*args, &block)
        Connection.send(:head, @path, *args, &block)
      end
    end

    # set ApiResource's http 
    def self.init
      ::ApiResource::Connection.class_eval do
        private
        alias_method :http_without_mock, :http
        def http(path)
          Interface.new(path)
        end
      end
    end
    
    # set ApiResource's http 
    def self.remove
      ::ApiResource::Connection.class_eval do
        private
        alias_method :http, :http_without_mock
      end
    end

    # clear out the defined mocks
    def self.clear_endpoints
      ret = @@endpoints
      @@endpoints = {}
      ret
    end
    # re-set the endpoints
    def self.set_endpoints(new_endpoints)
      @@endpoints = new_endpoints
    end
    # return the defined endpoints
    def self.endpoints
      @@endpoints
    end
    def self.define(&block)
      instance_eval(&block) if block_given?
    end
    # define an endpoint for the mock
    def self.endpoint(path, &block)
      path, format = path.split(".")
      @@endpoints[path] ||= []
      with_path_and_format(path, format) do
        instance_eval(&block) if block_given?
      end
    end
    # find a matching response
    def self.find_response(request)
      # these are stored as [[Request, Response], [Request, Response]]
      responses_and_params = self.responses_for_path(request.path)
      ret = (responses_and_params[:responses] || []).select{|pair| pair.first.match?(request)}
      raise Exception.new("More than one response matches #{request}") if ret.length > 1
      return ret.first ? {:response => ret.first[1], :params => responses_and_params[:params]} : nil
    end

    def self.paths_match?(known_path, entered_path)
      PathString.paths_match?(known_path, entered_path)
    end

    # This method assumes that the two are matching paths
    # if they aren't the behavior is undefined
    def self.extract_params(known_path, entered_path)
      PathString.extract_params(known_path, entered_path)
    end

    # returns a hash {:responses => [[Request, Response],[Request,Response]], :params => {...}}
    # if there is no match returns nil
    def self.responses_for_path(path)
      path = path.split("?").first
      path = path.split(/\./).first
      # The obvious case
      if @@endpoints[path]
        return {:responses => @@endpoints[path], :params => {}}
      end
      # parameter names prefixed with colons should match parts
      # of the path and push those parameters into the response
      @@endpoints.keys.each do |possible_path|
        if self.paths_match?(possible_path, path)
          return {:responses => @@endpoints[possible_path], :params => self.extract_params(possible_path, path)}
        end
      end

      return {:responses => nil, :params => nil}
    end
    

    private
    def self.with_path_and_format(path, format, &block)
      @@path, @@format = path, format
      ret = yield
      @@path, @@format = nil, nil
      ret
    end
    # define the 
    [:post, :put, :get, :delete, :head].each do |verb|
      instance_eval <<-EOE, __FILE__, __LINE__ + 1
        def #{verb}(response_body, opts = {}, &block)

          raise Exception.new("Must be called from within an endpoint block") unless @@path
          opts = opts.reverse_merge({:status_code => 200, :response_headers => {}, :params => {}})        

          @@endpoints[@@path] << [MockRequest.new(:#{verb}, @@path, :params => opts[:params], :format => @@format), MockResponse.new(response_body, :status_code => opts[:status_code], :headers => opts[:response_headers], :format => @@format, &block)]
        end
      EOE
    end

    class MockResponse
      attr_reader :body, :headers, :code, :format, :block
      def initialize(body, opts = {}, &block)     
        opts = opts.reverse_merge({:headers => {}, :status_code => 200})
        @body = body
        @headers = opts[:headers]
        @code = opts[:status_code]
        @format = (opts[:format] || :json)
        @block = block if block_given?
      end
      def []=(key, val)
        @headers[key] = val
      end
      def [](key)
        @headers[key]
      end

      def body
        raise Exception.new("Body must respond to to_#{self.format}") unless @body.respond_to?("to_#{self.format}")
        @body.send("to_#{self.format}")
      end

      def body_as_object
        return @body
      end

      def generate_response(params)
        @body = @body.instance_exec(params, &self.block) if self.block
      end
    end

    class MockRequest
      attr_reader :method, :path, :body, :headers, :params, :format, :query

      def initialize(method, path, opts = {})
        @method = method.to_sym

        # set the normalized path, format and query string
        @path, @query = path.split("?")
        @path, @format = @path.split(".")

        # if we have params, it is a MockRequest definition
        if opts[:params]
          @params = opts[:params]
          # otherwise, we need to check either the query string or the body
          # depending on the http verb
        else
          case @method
            when :post, :put
              @params = JSON.parse(opts[:body] || "")
            when :get, :delete, :head
              @params = sorted_params(@query || "")
          end
        end
        @body = opts[:body]
        @headers = opts[:headers] || {}
        @headers["Content-Length"] = @body.blank? ? "0" : @body.size.to_s
      end

      # 
      def sorted_params(data)
        ret = {}
        data.split("&").each do |val|
          val = val.split("=")
          if val.last =~ /^\d+$/
            ret[val.first] = val.last.to_i
          elsif val.last =~ /^[\d\.]+$/
            ret[val.first] = val.last.to_f
          elsif val.last == "true"
            ret[val.first] = true
          elsif val.last == "false"
            ret[val.first] = false  
          else
            ret[val.first] = val.last
          end
        end
        ret
      end

      # because of the context these come from, we can assume that the path already matches
      def match?(request)
        return false unless self.method == request.method
        return false unless self.format == request.format || request.format.nil? || self.format.nil?
        Comparator.diff(self.params, request.params) == {}
      end
      # string representation
      def to_s
        "#{self.method.upcase} #{self.format} #{self.path} #{self.params}"
      end
    end
    class Connection

      cattr_accessor :requests
      self.requests = []

      #   body?       methods
      { true  => %w(post put),
        false => %w(get delete head) }.each do |has_body, methods|
        methods.each do |method|
          # def post(path, body, headers)
          #   request = ApiResource::Request.new(:post, path, body, headers)
          #   self.class.requests << request
          #   if response = LifebookerClient::Mocks.find_response(request)
          #     response
          #   else
          #     raise InvalidRequestError.new("Could not find a response recorded for #{request.to_s} - Responses recorded are: - #{inspect_responses}")
          #   end
          # end
          instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def #{method}(path, #{'body, ' if has_body}headers)
              opts = {:headers => headers}
              #{"opts[:body] = body" if has_body}
              request = MockRequest.new(:#{method}, path, opts)
              self.requests << request
              if response = Mocks.find_response(request)
                response[:response].tap{|resp| resp.generate_response(response[:params])}
              else
                raise ApiResource::ResourceNotFound.new(
                  MockResponse.new("", {:headers => {"Content-type" => "application/json"}, :status_code => 404}),
                  :message => "\nCould not find a response recorded for \#{request.pretty_inspect}\n" +
                  "Potential Responses Are:\n" +
                  "\#{Array.wrap(Mocks.responses_for_path(request.path)[:responses]).collect(&:first).pretty_inspect}"
                )
              end
            end
          EOE
        end
      end
    end
  end
end