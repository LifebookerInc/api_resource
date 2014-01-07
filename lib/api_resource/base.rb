require 'pp'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/string_inquirer'

module ApiResource

  class Base

    # TODO: There's way too much in this class as it stands, some glaring problems:
    # => 1) class_attributes for connection options belong in the connection class
    # => 2) Attributes about serialization belong with the serializers
    # => 3) Logging seems to be an unmitigated disaster
    # => 4) All the resource definition should be in its own module with the data mapper implementation
    # => 5) Random shit about tokens all over the place, clearly does not belong
    # => 6) Everything related to the pathing should go somewhere by itself
    # => 7) Everything about saving should go in a persistence module
    # => 8) Everything about loading data should go in a Finder module
    # => 9) Delete serializable_hash and start again
    # => 10) setup_create_call and setup_update_call should modify the results from another method
    # => 11) nil_attributes probably belongs with the attributes
    # => 12) Add instrumentation in some key places

    # Other Random TODOs:
    # => 1) Profile and benchmark this code
    # => 2) Deal with arrays and hashes as attributes in a more reasonable way
    # => 3) Finish implementing typecasting (to_api portion)
    # => 4) Add a reasonable way to load and activate observers, verify that it works
    # => 5) Hook up the custom_methods module
    # => 6) Implement an IdentityMap
    # => 7) Write documentation
    # => 8) Write Examples

    class_attribute(
      :site,
      :proxy,
      :user,
      :password,
      :auth_type,
      :format,
      :timeout,
      :open_timeout,
      :ssl_options,
      :token,
      :ttl,
      { instance_writer: false, instance_reader: false }
    )
    self.format = ApiResource::Formats::JsonFormat

    class_attribute(:include_root_in_json)
    self.include_root_in_json = true

    class_attribute(:include_nil_attributes_on_create)
    self.include_nil_attributes_on_create = false

    class_attribute(:include_all_attributes_on_update)
    self.include_nil_attributes_on_create = false

    delegate :logger, to: ApiResource

    class << self

      # @!attribute [w] collection_name
      #   @return [String]
      attr_writer :collection_name

      # @!attribute [w] element_name
      #   @return [String]
      attr_writer :element_name

      delegate :logger,
        to: ApiResource

      #
      # Accessor for the connection
      #
      # @param  refresh = false [Boolean] Whether to reconnect
      #
      # @return [Connection]
      def connection(refresh = false)
        if refresh || @connection.nil?
          @connection = Connection.new(self.site, self.format, self.headers)
        end
        @connection.timeout = self.timeout
        @connection
      end

      #
      # Handles the setting of format to a MimeType
      #
      # @param  mime_type_or_format [Symbol, MimeType]
      #
      # @return [MimeType] The new MimeType
      def format_with_mimetype_or_format_set=(mime_type_or_format)
        if mime_type_or_format.is_a?(Symbol)
          format = ApiResource::Formats[mime_type_or_format]
        else
          format = mime_type_or_format
        end
        self.format_without_mimetype_or_format_set = format
        if self.site
          self.connection.format = format
        end
        format
      end
      alias_method_chain :format=, :mimetype_or_format_set

      #
      # Reader for headers
      #
      # @return [Hash] Headers for requests
      def headers
        {}.tap do |ret|
          ret['Lifebooker-Token'] = self.token if self.token.present?
        end
      end

      def inherited(klass)
        # Call the methods of the superclass to make sure inheritable accessors and the like have been inherited
        super
        # Now we need to define the inherited method on the klass that's doing the inheriting
        # it calls super which will allow the chaining effect we need
        klass.instance_eval <<-EOE, __FILE__, __LINE__ + 1
          def inherited(klass)
            klass.send(:define_singleton_method, :collection_name, lambda {self.superclass.collection_name})
            super(klass)
          end
        EOE
        true
      end

      #
      # Explicit call to load the resource definition
      #
      # @return [Boolean] True if we loaded it, false if it was already
      # loaded
      def load_resource_definition
        unless instance_variable_defined?(:@resource_definition)
          # Lock the mutex to make sure only one thread does
          # this at a time
          self.resource_definition_mutex.synchronize do
            # once we have the lock, check to make sure the resource
            # definition wasn't fetched while we were sleeping
            return true if instance_variable_defined?(:@resource_definition)
            # the last time we checked
            @resource_load_time = Time.now

            # set to not nil so we don't get an infinite loop
            @resource_definition = true
            self.set_class_attributes_upon_load
            return true
          end
        end
        # we didn't do anything
        false
      end

      #
      # Set the open timeout on the connection and connect
      #
      # @param  timeout [Fixnum] Open timeout in number of seconds
      #
      # @return [Fixnum] The timeout
      def open_timeout_with_connection_reset=(timeout)
        @connection = nil
        self.open_timeout_without_connection_reset = timeout
      end
      alias_method_chain :open_timeout=, :connection_reset

      #
      # Prefix for the resource path
      #
      # @todo Are the options used?
      #
      # @param  options = {} [Hash] Options
      #
      # @return [String] Collection prefix
      def prefix(options = {})
        default = (self.site ? self.site.path : '/')
        default << '/' unless default[-1..-1] == '/'
        self.prefix = default
        prefix(options)
      end

      #
      # @todo  Not sure what this does
      def prefix_source
        prefix
        prefix_source
      end

      #
      # Clear the old resource definition and reload it from the
      # server
      #
      # @return [Boolean] True if it loaded
      def reload_resource_definition
        # clear the public_attribute_names, protected_attribute_names
        if instance_variable_defined?(:@resource_definition)
          remove_instance_variable(:@resource_definition)
          self.clear_attributes
          self.clear_related_objects
        end
        self.load_resource_definition
      end
      # backwards compatibility
      alias_method :reload_class_attributes, :reload_resource_definition

      #
      # Mutex so that multiple Threads don't try to load the resource
      # definition at the same time
      #
      # @return [Mutex]
      def resource_definition_mutex
        @resource_definition_mutex ||= Mutex.new
      end

      #
      # Reset our connection instance so that we will reconnect the
      # next time we need it
      #
      # @return [Boolean] true
      def reset_connection
        remove_instance_variable(:@connection) if @connection.present?
        true
      end

      #
      # Reader for the resource_definition
      #
      # @return [Hash, nil] Our stored resource definition
      def resource_definition
        @resource_definition
      end

      #
      # Load our resource definition to make sure we know what this class
      # responds to
      #
      # @return [Boolean] Whether or not it responss
      def respond_to?(*args)
        self.load_resource_definition
        super
      end

      #
      # This makes a request to new_element_path and sets up the correct
      # attribute, scope and association methods for this class
      #
      # @return [Boolean] true
      def set_class_attributes_upon_load
        # this only happens in subclasses
        return true if self == ApiResource::Base
        begin
          @resource_definition = self.connection.get(
            self.new_element_path, self.headers
          )
          # set up methods derived from our class definition
          self.define_all_attributes
          self.define_all_scopes
          self.define_all_associations

        # Swallow up any loading errors because the site may be incorrect
        rescue Exception => e
          self.handle_resource_definition_error(e)
        end
        true
      end

      #
      # Handles the setting of site while reloading the resource
      # definition to ensure we have the latest definition
      #
      # @param  site [String] URL of the site
      #
      # @return [String] The newly set site
      def site_with_connection_reset=(site)
        # store so we can reload attributes if the site changed
        old_site = self.site.to_s.clone
        @connection = nil

        if site.nil?
          self.site_without_connection_reset = nil
          # no site, so we'll skip the reload
          return site
        else
          self.site_without_connection_reset = create_site_uri_from(site)
        end

        # reset class attributes and try to reload them if the site changed
        unless self.site.to_s == old_site
          self.reload_resource_definition
        end

        return site
      end
      alias_method_chain :site=, :connection_reset

      #
      # Set the timeout on the connection and connect
      #
      # @param  timeout [Fixnum] Timeout in number of seconds
      #
      # @return [Fixnum] The timeout
      def timeout_with_connection_reset=(timeout)
        @connection = nil
        self.timeout_without_connection_reset = timeout
      end
      alias_method_chain :timeout=, :connection_reset

      #
      # Handles the setting of tokens on descendants
      #
      # @param  new_token [String] New token string
      #
      # @return [String] The token that was set
      def token_with_new_token_set=(new_token)
        self.token_without_new_token_set = new_token
        self.connection(true)
        self.descendants.each do |child|
          child.send(:token=, new_token)
        end
        new_token
      end
      alias_method_chain :token=, :new_token_set




      def prefix=(value = '/')
        prefix_call = value.gsub(/:\w+/) { |key|
          "\#{URI.escape options[#{key}].to_s}"
        }
        @prefix_parameters = nil
        silence_warnings do
          instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def prefix_source() "#{value}" end
            def prefix(options={})
              ret = "#{prefix_call}"
              ret =~ Regexp.new(Regexp.escape("//")) ? "/" : ret
            end
          EOE
        end
      rescue Exception => e
        logger.error "Couldn't set prefix: #{e}\n #{code}" if logger
        raise
      end

      # element_name with default
      def element_name
        @element_name ||= self.model_name.element
      end
      # collection_name with default
      def collection_name
        @collection_name ||= ActiveSupport::Inflector.pluralize(self.element_name)
      end

      # alias_method :set_prefix, :prefix=
      # alias_method :set_element_name, :element_name=
      # alias_method :set_collection_name, :collection_name=

      def element_path(id, prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?

        # If we have a prefix, we need a foreign key id
        # This regex detects '//', which means no foreign key id is present.
        if prefix(prefix_options) =~ /\/\/$/
          "/#{collection_name}/#{URI.escape id.to_s}.#{format.extension}#{query_string(query_options)}"
        else
          # Fall back on this rather than search without the id
          "#{prefix(prefix_options)}#{collection_name}/#{URI.escape id.to_s}.#{format.extension}#{query_string(query_options)}"
        end
      end

      # path to find
      def new_element_path(prefix_options = {})
        url = File.join(
          self.prefix(prefix_options),
          self.collection_name,
          "new.#{format.extension}"
        )
        if self.superclass != ApiResource::Base && self.name.present?
          url = "#{url}?type=#{self.name.demodulize}" 
        end
        return url
      end

      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?

        # Fall back on this rather than search without the id
        "#{prefix(prefix_options)}#{collection_name}.#{format.extension}#{query_string(query_options)}"
      end

      def build(attributes = {})
        self.new(attributes)
      end

      def create(attributes = {})
        self.new(attributes).tap{ |resource| resource.save }
      end


      # Deletes the resources with the ID in the +id+ parameter.
      #
      # ==== Options
      # All options specify \prefix and query parameters.
      #
      # ==== Examples
      #   Event.delete(2) # sends DELETE /events/2
      #
      #   Event.create(name: 'Free Concert', location: 'Community Center')
      #   my_event = Event.find(:first) # let's assume this is event with ID 7
      #   Event.delete(my_event.id) # sends DELETE /events/7
      #
      #   # Let's assume a request to events/5/cancel.xml
      #   Event.delete(params[:id]) # sends DELETE /events/5
      def delete(id, options = {})
        connection.delete(element_path(id, options))
      end

      # do we have an invalid resource
      def resource_definition_is_invalid?
        # if we have a Hash, it's valid
        return false if @resource_definition.is_a?(Hash)
        # if we have no recheck time, it's invalid
        return true if @resource_load_time.nil?
        # have we checked in the last minute?
        return @resource_load_time < Time.now - 1.minute
      end

      # split an option hash into two hashes, one containing the prefix options,
        # and the other containing the leftovers.
      def split_options(options = {})
        prefix_options, query_options = {}, {}
        (options || {}).each do |key, value|
          next if key.blank?
          (prefix_parameters.include?(key.to_sym) ? prefix_options : query_options)[key.to_sym] = value
        end

        [ prefix_options, query_options ]
      end

      protected

        #
        # Handle any errors raised during the resource definition
        # find
        #
        # @param  e [Exception] Exception thrown
        #
        # @raise [Exception] Re-raised if
        # ApiResource.raise_missing_definition_error is true
        #
        # @return [ApiResource::Request, nil] The Request associated with
        # this error or nil if there is no request and the error came from
        # something else
        def handle_resource_definition_error(e)
          if ApiResource.raise_missing_definition_error
            raise e
          end
          ApiResource.logger.warn(
            "#{self} accessing #{self.new_element_path}"
          )
          ApiResource.logger.warn(
            "#{self}: #{e.message[0..60].gsub(/[\n\r]/, '')} ...\n"
          )
          ApiResource.logger.debug(e.backtrace.pretty_inspect)
          return e.respond_to?(:request) ? e.request : nil
        end

        def method_missing(meth, *args, &block)
          # make one attempt to load remote attrs
          if self.resource_definition_is_invalid?
            self.reload_resource_definition
          end
          # see if we respond to the method now
          if self.respond_to?(meth)
            return self.send(meth, *args, &block)
          else
            super
          end
        end

      private

        # Accepts a URI and creates the site URI from that.
        def create_site_uri_from(site)
          site.is_a?(URI) ? site.dup : uri_parser.parse(site)
        end

        # Accepts a URI and creates the proxy URI from that.
        def create_proxy_uri_from(proxy)
          proxy.is_a?(URI) ? proxy.dup : uri_parser.parse(proxy)
        end

        # contains a set of the current prefix parameters.
        def prefix_parameters
          @prefix_parameters ||= prefix_source.scan(/:\w+/).map { |key| key[1..-1].to_sym }.to_set
        end

        # Builds the query string for the request.
        def query_string(options)
          "?#{options.to_query}" unless options.nil? || options.empty?
        end

        def uri_parser
          @uri_parser ||= URI.const_defined?(:Parser) ? URI::Parser.new : URI
        end

    end

    def initialize(attributes = {})
      # call super's initialize to set up any variables that we need
      super(attributes)
      # if we initialize this class, load the attributes
      self.class.load_resource_definition
      # Now we can make a call to setup the inheriting
      # klass with its attributes
      self.attributes = attributes
    end

    def new?
      id.blank?
    end
    alias :new_record? :new?

    def persisted?
      !new?
    end

    def id
      self.read_attribute(self.class.primary_key)
    end

    # Bypass dirty tracking for this field
    def id=(id)
      @attributes[self.class.primary_key] = id
    end

    def ==(other)
      other.equal?(self) || (other.instance_of?(self.class) && other.id == self.id)
    end

    def eql?(other)
      self == other
    end

    def hash
      id.hash
    end

    def dup
      self.class.instantiate_record(self.attributes)
    end

    #
    # Implementation of to_key for use in Rails forms
    #
    # @return [Array<Fixnum>,nil] Array wrapped id or nil
    def to_key
      [self.id] if self.id.present?
    end

    def update_attributes(attrs)
      self.attributes = attrs
      self.save
    end

    def save(*args)
      new? ? create(*args) : update(*args)
    end

    def save!(*args)
      save(*args) || raise(ApiResource::ResourceInvalid.new(self))
    end

    def destroy
      connection.delete(element_path(self.id), self.class.headers)
    end

    def encode(options = {})
      self.send("to_#{self.class.format.extension}", options)
    end

    def reload
      # find the record from the remote service
      reloaded = self.class.find(self.id)

      # clear out the attributes cache
      @attributes_cache = HashWithIndifferentAccess.new
      # set up our attributes cache on our record
      @attributes = reloaded.instance_variable_get(:@attributes)

      reloaded
    end

    def to_param
      # Stolen from active_record.
      # We can't use alias_method here, because method 'id' optimizes itself on the fly.
      id && id.to_s # Be sure to stringify the id for routes
    end

    def prefix_options
      return {} unless self.class.prefix_source =~ /\:/
      ret = {}
      self.prefix_attribute_names.each do |name|
        ret[name] = self.send(name)
      end
      ret
    end

    def prefix_attribute_names
      return [] unless self.class.prefix_source =~ /\:/
      self.class.prefix_source.scan(/\:(\w+)/).collect{|match| match.first.to_sym}
    end

    # Override to_s and inspect so they only show attributes
    # and not associations, this prevents force loading of associations
    # when we call to_s or inspect on a descendent of base but allows it if we
    # try to evaluate an association directly
    def to_s
      return "#<#{self.class}:#{(self.object_id * 2).to_s(16)} @attributes=#{self.attributes}"
    end
    alias_method :inspect, :to_s

    # Methods for serialization as json or xml, relying on the serializable_hash method
    def to_xml(options = {})
      self.serializable_hash(options).to_xml(root: self.class.element_name)
    end

    def to_json(options = {})
      # handle whether or not we include root in our JSON
      if self.class.include_root_in_json
        ret = {
          self.class.element_name => self.serializable_hash(options)
        }
      else
        ret = self.serializable_hash(options)
      end
      ret.to_json
    end

    # TODO: (Updated 10/26/2013):
    # Leaving this old message here though the behavior is now in Serializer.
    # Any changes should be done there
    #
    # this method needs to change seriously to fit in with the
    # new typecasting scheme, it should call self.outgoing_attributes which
    # should return the converted versions after calling to_api, that should
    # be implemented in the attributes module though
    def serializable_hash(options = {})
      return Serializer.new(self, options).to_hash
    end

    protected
    def connection(refresh = false)
      self.class.connection(refresh)
    end

    def load_attributes_from_response(response)
      if response.present?
        @attributes_cache = {}
        @attributes = @attributes.merge(
          response.with_indifferent_access
        )
      end
      response
    end

    # def method_missing(meth, *args, &block)
    #   # make one attempt to load remote attrs
    #   if self.class.resource_definition_is_invalid?
    #     self.class.reload_resource_definition
    #   end
    #   # see if we respond to the method now
    #   if self.respond_to?(meth)
    #     return self.send(meth, *args, &block)
    #   else
    #     super
    #   end
    # end

    def element_path(id, prefix_override_options = {}, query_options = nil)
      self.class.element_path(
        id,
        self.prefix_options.merge(prefix_override_options),
        query_options
      )
    end

    # list of all attributes that are not nil
    def nil_attributes
      self.attributes.select{|k,v|
        # if our value is actually nil or if we are an association
        # or array and we are blank
        v.nil? || ((self.association?(k) || v.is_a?(Array)) && v.blank?)
      }
    end

    def new_element_path(prefix_options = {})
      self.class.new_element_path(prefix_options)
    end

    def collection_path(override_prefix_options = {},query_options = nil)
      self.class.collection_path(
        self.prefix_options.merge(override_prefix_options),
        query_options
      )
    end

    #
    # Create a new record
    # @param  *args [type] [description]
    #
    # @return [type] [description]
    def create(*args)
      path = self.collection_path
      body = self.setup_create_call(*args)
      headers = self.class.headers
      # make the post call
      connection.post(path, body, headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    #
    # Helper method to set up a call to create
    #
    # @param  *args [type] [description]
    #
    # @return [type] [description]
    def setup_create_call(*args)
      opts = args.extract_options!

      # handle nil attributes
      opts[:include_nil_attributes] = self.include_nil_attributes_on_create

      # more generic setup_save_call
      self.setup_save_call(args, opts)
    end


    def update(*args)
      path = self.element_path(self.id)
      body = self.setup_update_call(*args)
      headers = self.class.headers
      # We can just ignore the response
      connection.put(path, body, headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    def setup_update_call(*args)
      options = args.extract_options!

      # When we create we should not include any blank attributes
      options[:include_nil_attributes] =
        self.include_all_attributes_on_update

      # exclude unchanged data
      unless self.include_all_attributes_on_update
        options[:except] ||= []
        options[:except].concat(
          self.attribute_names.select { |name| self.changes[name].blank? }
        )
      end

      # more generic setup_save_call
      self.setup_save_call(args, options)
    end

    def setup_save_call(additional_associations, options = {})
      # We pass in associations as options and args for no good reason
      options[:include_associations] ||= []
      options[:include_associations].concat(additional_associations)

      # get our data
      data = self.serializable_hash(options)

      # handle the root element
      if self.include_root_in_json
        data = { self.class.element_name.to_sym => data}
      end

      return data
    end

    private

    def split_options(options = {})
      self.class.__send__(:split_options, options)
    end

  end

  class Base
    extend ActiveModel::Naming
    # Order is important here
    # It should be Validations, Dirty Tracking, Callbacks so the include order is the opposite
    include AssociationActivation
    self.activate_associations

    include Scopes, Callbacks, Observing, Attributes, ModelErrors, Conditions, Finders, Typecast

  end

end