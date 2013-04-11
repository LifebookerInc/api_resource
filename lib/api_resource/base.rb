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
    
    class_attribute :site, :proxy, :user, :password, :auth_type, :format, 
      :timeout, :open_timeout, :ssl_options, :token, :ttl
    

    class_attribute :include_root_in_json
    self.include_root_in_json = true
    
    class_attribute :include_nil_attributes_on_create
    self.include_nil_attributes_on_create = false
    
    class_attribute :include_all_attributes_on_update
    self.include_nil_attributes_on_create = false

    class_attribute :format
    self.format = ApiResource::Formats::JsonFormat
    
    class_attribute :primary_key
    self.primary_key = "id"

    delegate :logger, :to => ApiResource
    
    class << self
      
      # writers - accessors with defaults were not working
      attr_writer :element_name, :collection_name

      delegate :logger, :to => ApiResource
      
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

      def resource_definition
        @resource_definition
      end

      # This makes a request to new_element_path
      def set_class_attributes_upon_load
        return true if self == ApiResource::Base
        begin
          @resource_definition = self.connection.get(
            self.new_element_path, self.headers
          )
          # Attributes go first
          if resource_definition["attributes"]
            
            define_attributes(
              *(resource_definition["attributes"]["public"] || [])
            )
            define_protected_attributes(
              *(resource_definition["attributes"]["protected"] || [])
            ) 
            
          end
          # Then scopes
          if resource_definition["scopes"]
            resource_definition["scopes"].each_pair do |scope_name, opts|
              self.scope(scope_name, opts)
            end
          end
          # Then associations
          if resource_definition["associations"]
            resource_definition["associations"].each_pair do |key, hash|
              hash.each_pair do |assoc_name, assoc_options|
                self.send(key, assoc_name, assoc_options)
              end
            end
          end
          
          # This is provided by ActiveModel::AttributeMethods, it should
          # define the basic methods but we need to override all the setters 
          # so we do dirty tracking
          attrs = []
          if resource_definition["attributes"] && resource_definition["attributes"]["public"]
            attrs += resource_definition["attributes"]["public"].collect{|v| 
              v.is_a?(Array) ? v.first : v
            }.flatten
          end
          if resource_definition["associations"]
            attrs += resource_definition["associations"].values.collect(&:keys).flatten
          end
          
        # Swallow up any loading errors because the site may be incorrect
        rescue Exception => e
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
      end
      
      def reset_connection
        remove_instance_variable(:@connection) if @connection.present?
      end

      # load our resource definition to make sure we know what this class
      # responds to
      def respond_to?(*args)
        self.load_resource_definition
        super
      end
      
      def load_resource_definition
        unless instance_variable_defined?(:@resource_definition)
          # the last time we checked
          @resource_load_time = Time.now
        
          # set to not nil so we don't get an infinite loop
          @resource_definition = true
          self.set_class_attributes_upon_load
          return true
        end
        # we didn't do anything
        false
      end

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
      
      def token_with_new_token_set=(new_token)
        self.token_without_new_token_set = new_token
        self.connection(true)
        self.descendants.each do |child|
          child.send(:token=, new_token)
        end
      end
      
      alias_method_chain :token=, :new_token_set

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
      
      
      def format_with_mimetype_or_format_set=(mime_type_or_format)
        format = mime_type_or_format.is_a?(Symbol) ? ApiResource::Formats[mime_type_or_format] : mime_type_or_format
        self.format_without_mimetype_or_format_set = format
        self.connection.format = format if self.site
      end
      
      alias_method_chain :format=, :mimetype_or_format_set
      
      def timeout_with_connection_reset=(timeout)
        @connection = nil
        self.timeout_without_connection_reset = timeout
      end
      
      alias_method_chain :timeout=, :connection_reset
      
      def open_timeout_with_connection_reset=(timeout)
        @connection = nil
        self.open_timeout_without_connection_reset = timeout
      end
      
      alias_method_chain :open_timeout=, :connection_reset
      
      def connection(refresh = false)
        @connection = Connection.new(self.site, self.format, self.headers) if refresh || @connection.nil?
        @connection.timeout = self.timeout
        @connection
      end
            
      def headers
        {}.tap do |ret|
          ret['Lifebooker-Token'] = self.token if self.token.present?
        end
      end
      
      def prefix(options = {})
        default = (self.site ? self.site.path : '/')
        default << '/' unless default[-1..-1] == '/'
        self.prefix = default
        prefix(options)
      end
      
      def prefix_source
        prefix
        prefix_source
      end

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
        File.join(
          self.prefix(prefix_options), 
          self.collection_name, 
          "new.#{format.extension}"
        )
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
      #   Event.create(:name => 'Free Concert', :location => 'Community Center')
      #   my_event = Event.find(:first) # let's assume this is event with ID 7
      #   Event.delete(my_event.id) # sends DELETE /events/7
      #
      #   # Let's assume a request to events/5/cancel.xml
      #   Event.delete(params[:id]) # sends DELETE /events/5
      def delete(id, options = {})
        connection.delete(element_path(id, options))
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

        # do we have an invalid resource
        def resource_definition_is_invalid?
          # if we have a Hash, it's valid
          return false if @resource_definition.is_a?(Hash)
          # if we have no recheck time, it's invalid
          return true if @resource_load_time.nil?
          # have we checked in the last minute?
          return @resource_load_time < Time.now - 1.minute
        end

        def method_missing(meth, *args, &block)
          ApiResource.logger.info("CALLING #{meth}")
          # make one attempt to load remote attrs
          if self.resource_definition_is_invalid?
            self.reload_resource_definition
          end
          # see if we respond to the method now
          if self.response_to?(meth)
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
      self.serializable_hash(options).to_xml(:root => self.class.element_name)
    end
    
    def to_json(options = {})
      self.class.include_root_in_json ? {self.class.element_name => self.serializable_hash(options)}.to_json : self.serializable_hash(options).to_json
    end
    
    # TODO: this method needs to change seriously to fit in with the
    # new typecasting scheme, it should call self.outgoing_attributes which
    # should return the converted versions after calling to_api, that should
    # be implemented in the attributes module though
    def serializable_hash(options = {})
      
      action = options[:action]
      
      include_nil_attributes = options[:include_nil_attributes]
      
      options[:include_associations] = options[:include_associations] ? options[:include_associations].symbolize_array : self.changes.keys.symbolize_array.select{|k| self.association?(k)}
      
      options[:include_extras] = options[:include_extras] ? options[:include_extras].symbolize_array : []
      
      options[:except] ||= []
      
      ret = self.attributes.inject({}) do |accum, (key,val)|
        # If this is an association and it's in include_associations then include it
        if options[:include_extras].include?(key.to_sym)
          accum.merge(key => val)
        elsif options[:except].include?(key.to_sym)
          accum
        # this attribute is already accounted for in the URL
        elsif self.prefix_attribute_names.include?(key.to_sym)
          accum
        elsif(!include_nil_attributes && val.nil? && self.changes[key].blank?)
          accum
        else
          !self.attribute?(key) || self.protected_attribute?(key) ? accum : accum.merge(key => val)
        end
      end

      # also add in the _id fields that are changed
      ret = self.association_names.inject(ret) do |accum, assoc_name|
        id_method = self.class.association_foreign_key_field(assoc_name)
        if self.changes[id_method].present?
          accum[id_method] = self.changes[id_method].last
        end
        accum
      end

      options[:include_associations].each do |assoc|
        if self.association?(assoc)
          ret[assoc] = self.send(assoc).serializable_hash({
            :include_id => true, 
            :include_nil_attributes => include_nil_attributes, 
            :action => action
          })
        end
      end
      # include id - this is for nested updates
      ret[:id] = self.id if options[:include_id] && !self.new?
      ret
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
    
    def create(*args)
      body = setup_create_call(*args)
      connection.post(collection_path, body, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    def setup_create_call(*args)
      opts = args.extract_options!
      # When we create we should not include any blank attributes unless they are associations
      except = self.class.include_nil_attributes_on_create ? 
        {} : self.nil_attributes
      opts[:except] = opts[:except] ? opts[:except].concat(except.keys).uniq.symbolize_array : except.keys.symbolize_array
      opts[:include_nil_attributes] = self.class.include_nil_attributes_on_create
      opts[:include_associations] = opts[:include_associations] ? opts[:include_associations].concat(args) : []
      opts[:include_extras] ||= []
      opts[:action] = "create"
      # TODO: Remove this dependency for saving files
      body = RestClient::Payload.has_file?(self.attributes) ? self.serializable_hash(opts) : encode(opts)
    end

    
    def update(*args)
      body = setup_update_call(*args)
      # We can just ignore the response
      connection.put(element_path(self.id), body, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    def setup_update_call(*args)
      opts = args.extract_options!
      # When we create we should not include any blank attributes
      except = self.class.attribute_names - self.changed.symbolize_array
      changed_associations = self.changed.symbolize_array.select{|item| self.association?(item)}
      opts[:except] = opts[:except] ? opts[:except].concat(except).uniq.symbolize_array : except.symbolize_array
      opts[:include_nil_attributes] = self.include_all_attributes_on_update
      opts[:include_associations] = opts[:include_associations] ? opts[:include_associations].concat(args).concat(changed_associations).uniq : changed_associations.concat(args)
      opts[:include_extras] ||= []
      opts[:action] = "update"
      opts[:except] = [:id] if self.class.include_all_attributes_on_update
      # TODO: Remove this dependency for saving files
      body = RestClient::Payload.has_file?(self.attributes) ? self.serializable_hash(opts) : encode(opts)
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
