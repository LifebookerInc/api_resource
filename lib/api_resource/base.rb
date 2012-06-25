require 'pp'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/string_inquirer'

module ApiResource
  
  class Base
    
    class_attribute :site, :proxy, :user, :password, :auth_type, :format, 
      :timeout, :open_timeout, :ssl_options, :token, :ttl
    

    class_attribute :include_root_in_json
    self.include_root_in_json = true
    
    class_attribute :include_blank_attributes_on_create
    self.include_blank_attributes_on_create = false
    
    class_attribute :include_all_attributes_on_update
    self.include_blank_attributes_on_create = false

    class_attribute :format
    self.format = ApiResource::Formats::JsonFormat
    
    class_attribute :primary_key
    self.primary_key = "id"
    
    attr_accessor :prefix_options
    
    class << self
      
      # writers - accessors with defaults were not working
      attr_writer :element_name, :collection_name
      
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
      # This makes a request to new_element_path
      def set_class_attributes_upon_load
        return true if self == ApiResource::Base
        begin
          class_data = self.connection.get(
            self.new_element_path, self.headers
          )
          # Attributes go first
          if class_data["attributes"]
            
            define_attributes(
              *(class_data["attributes"]["public"] || [])
            )
            define_protected_attributes(
              *(class_data["attributes"]["protected"] || [])
            ) 
            
          end
          # Then scopes
          if class_data["scopes"]
            class_data["scopes"].each_pair do |scope_name, opts|
              self.scope(scope_name, opts)
            end
          end
          # Then associations
          if class_data["associations"]
            class_data["associations"].each_pair do |key, hash|
              hash.each_pair do |assoc_name, assoc_options|
                self.send(key, assoc_name, assoc_options)
              end
            end
          end
          
          # This is provided by ActiveModel::AttributeMethods, it should
          # define the basic methods but we need to override all the setters 
          # so we do dirty tracking
          attrs = []
          if class_data["attributes"] && class_data["attributes"]["public"]
            attrs += class_data["attributes"]["public"].collect{|v| 
              v.is_a?(Array) ? v.first : v
            }.flatten
          end
          if class_data["associations"]
            attrs += class_data["associations"].values.collect(&:keys).flatten
          end
          define_attribute_methods(attrs)
          
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
      
      def reload_class_attributes
        # clear the public_attribute_names, protected_attribute_names
        remove_instance_variable(:@class_data) if instance_variable_defined?(:@class_data)
        self.clear_attributes
        self.clear_related_objects
        self.set_class_attributes_upon_load
      end
      
      def token_with_new_token_set=(new_token)
        self.token_without_new_token_set = new_token
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
          self.reload_class_attributes
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
        @connection = Connection.new(self.site, self.format) if refresh || @connection.nil?
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
        prefix_call = value.gsub(/:\w+/) { |key| "\#{URI.escape options[#{key}].to_s}"}
        @prefix_parameters = nil
        silence_warnings do
          instance_eval <<-EOE, __FILE__, __LINE__ + 1
            def prefix_source() "#{value}" end
            def prefix(options={}) "#{prefix_call}" end
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
        "#{prefix(prefix_options)}#{collection_name}/#{URI.escape id.to_s}.#{format.extension}#{query_string(query_options)}"
      end
      
      def new_element_path(prefix_options = {})
        "#{prefix(prefix_options)}#{collection_name}/new.#{format.extension}"
      end
      
      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}#{collection_name}.#{format.extension}#{query_string(query_options)}"
      end
      
      def build(attributes = {})
        self.new(attributes)
      end
      
      def create(attributes = {})
        self.new(attributes).tap{ |resource| resource.save }
      end
      
      def find(*arguments)
        scope   = arguments.slice!(0)
        options = arguments.slice!(0) || {}

        case scope
          when :all   then find_every(options)
          when :first then find_every(options).first
          when :last  then find_every(options).last
          when :one   then find_one(options)
          else             find_single(scope, options)
        end
      end


      # A convenience wrapper for <tt>find(:first, *args)</tt>. You can pass
      # in all the same arguments to this method as you can to
      # <tt>find(:first)</tt>.
      def first(*args)
        find(:first, *args)
      end

      # A convenience wrapper for <tt>find(:last, *args)</tt>. You can pass
      # in all the same arguments to this method as you can to
      # <tt>find(:last)</tt>.
      def last(*args)
        find(:last, *args)
      end

      # This is an alias for find(:all).  You can pass in all the same
      # arguments to this method as you can to <tt>find(:all)</tt>
      def all(*args)
        find(:all, *args)
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
      
      protected
        def method_missing(meth, *args, &block)
          # make one attempt to load remote attrs
          unless self.instance_variable_defined?(:@class_data)
            self.set_class_attributes_upon_load
            self.instance_variable_set(:@class_data, true)
            return self.send(meth, *args, &block)
          end
          super
        end
      
      private
        # Find every resource
        def find_every(options)
          begin
            case from = options[:from]
            when Symbol
              instantiate_collection(get(from, options[:params]))
            when String
              path = "#{from}#{query_string(options[:params])}"
              instantiate_collection(connection.get(path, headers) || [])
            else
              prefix_options, query_options = split_options(options[:params])
              path = collection_path(prefix_options, query_options)
              instantiate_collection( (connection.get(path, headers) || []), prefix_options )
            end
          rescue ApiResource::ResourceNotFound
            # Swallowing ResourceNotFound exceptions and return nil - as per
            # ActiveRecord.
            nil
          end
        end

        # Find a single resource from a one-off URL
        def find_one(options)
          case from = options[:from]
          when Symbol
            instantiate_record(get(from, options[:params]))
          when String
            path = "#{from}#{query_string(options[:params])}"
            instantiate_record(connection.get(path, headers))
          end
        end

        # Find a single resource from the default URL
        def find_single(scope, options)
          prefix_options, query_options = split_options(options[:params])
          path = element_path(scope, prefix_options, query_options)
          instantiate_record(connection.get(path, headers), prefix_options)
        end

        def instantiate_collection(collection, prefix_options = {})
          collection.collect! { |record| instantiate_record(record, prefix_options) }
        end

        def instantiate_record(record, prefix_options = {})
          new(record).tap do |resource|
            resource.prefix_options = prefix_options
          end
        end


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

        def uri_parser
          @uri_parser ||= URI.const_defined?(:Parser) ? URI::Parser.new : URI
        end
       
    end
    
    def initialize(attributes = {})
      @prefix_options = {}
      # if we initialize this class, load the attributes
      unless self.class.instance_variable_defined?(:@class_data)
        self.class.set_class_attributes_upon_load
        self.class.instance_variable_set(:@class_data, true)
      end
      # Now we can make a call to setup the inheriting klass with its attributes
      load(attributes)
    end
    
    def new?
      id.blank?
    end
    alias :new_record? :new?
    
    def persisted?
      !new?
    end
    
    def id
      self.attributes[self.class.primary_key]
    end
    
    # Bypass dirty tracking for this field
    def id=(id)
      attributes[self.class.primary_key] = id
    end
    
    def ==(other)
      other.equal?(self) || (other.instance_of?(self.class) && other.id == self.id && other.prefix_options == self.prefix_options)
    end
    
    def eql?(other)
      self == other
    end
    
    def hash
      id.hash
    end
    
    def dup
      self.class.new.tap do |resource|
        resource.attributes = self.attributes
        resource.prefix_options = @prefix_options
      end
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
      self.load(self.class.find(to_param, :params => @prefix_options).attributes)
    end
    
    def to_param
      # Stolen from active_record.
      # We can't use alias_method here, because method 'id' optimizes itself on the fly.
      id && id.to_s # Be sure to stringify the id for routes
    end
    
    def load(attributes)
      return if attributes.nil?
      raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
      @prefix_options, attributes = split_options(attributes)
      attributes.symbolize_keys.each do |key, value|
        # If this attribute doesn't exist define it as a protected attribute
        self.class.define_protected_attributes(key) unless self.respond_to?(key)
        #self.send("#{key}_will_change!") if self.respond_to?("#{key}_will_change!")
        self.attributes[key] =
          case value
            when Array
              if self.has_many?(key)
                MultiObjectProxy.new(self.has_many_class_name(key), value)
              elsif self.association?(key)
                raise ArgumentError, "Expected a hash value or nil, got: #{value.inspect}"
              else
                typecast_attribute(key, value)
              end
            when Hash
              if self.has_many?(key)
                MultiObjectProxy.new(self.has_many_class_name(key), value)
              elsif self.association?(key)
                #binding.pry
                SingleObjectProxy.new(self.association_class_name(key), value)
              else
                typecast_attribute(key, value)
              end
            when NilClass
              # If it's nil and an association then create a blank object
              if self.has_many?(key)
                return MultiObjectProxy.new(self.has_many_class_name(key), [])
              elsif self.association?(key)
                SingleObjectProxy.new(self.association_class_name(key), value)
              end
            else
              raise ArgumentError, "expected an array or a hash for the association #{key}, got: #{value.inspect}" if self.association?(key)
              typecast_attribute(key, value)
          end
      end
      return self
    end
    
    # Override to_s and inspect so they only show attributes
    # and not associations, this prevents force loading of associations
    # when we call to_s or inspect on a descendent of base but allows it if we 
    # try to evaluate an association directly
    def to_s
      return "#<#{self.class}:#{(self.object_id * 2).to_s(16)} @attributes=#{self.attributes.inject({}){|accum,(k,v)| self.association?(k) ? accum : accum.merge(k => v)}}"
    end
    
    alias_method :inspect, :to_s
    
    # Methods for serialization as json or xml, relying on the serializable_hash method
    def to_xml(options = {})
      self.serializable_hash(options).to_xml(:root => self.class.element_name)
    end
    
    def to_json(options = {})
      self.class.include_root_in_json ? {self.class.element_name => self.serializable_hash(options)}.to_json : self.serializable_hash(options).to_json
    end
    
    def serializable_hash(options = {})
      action = options[:action]
      include_blank_attributes = options[:include_blank_attributes]
      options[:include_associations] = options[:include_associations] ? options[:include_associations].symbolize_array : self.changes.keys.symbolize_array.select{|k| self.association?(k)}
      options[:include_extras] = options[:include_extras] ? options[:include_extras].symbolize_array : []
      options[:except] ||= []
      ret = self.attributes.inject({}) do |accum, (key,val)|
        # If this is an association and it's in include_associations then include it
        if options[:include_extras].include?(key.to_sym)
          accum.merge(key => val)
        elsif options[:except].include?(key.to_sym) || (!include_blank_attributes && val.blank?)
          accum
        else
          !self.attribute?(key) || self.protected_attribute?(key) ? accum : accum.merge(key => val)
        end
      end
      options[:include_associations].each do |assoc|
        ret[assoc] = self.send(assoc).serializable_hash({:include_id => true, :include_blank_attributes => include_blank_attributes, :action => action}) if self.association?(assoc)
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
      load(response)
    end
    
    def element_path(id, prefix_options = {}, query_options = nil)
      self.class.element_path(id, prefix_options, query_options)
    end
    
    def new_element_path(prefix_options = {})
      self.class.new_element_path(prefix_options)
    end
    
    def collection_path(prefix_options = {},query_options = nil)
      self.class.collection_path(prefix_options, query_options)
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
      except = self.class.include_blank_attributes_on_create ? {} : self.attributes.select{|k,v| v.blank?}
      opts[:except] = opts[:except] ? opts[:except].concat(except.keys).uniq.symbolize_array : except.keys.symbolize_array
      opts[:include_blank_attributes] = self.class.include_blank_attributes_on_create
      opts[:include_associations] = opts[:include_associations] ? opts[:include_associations].concat(args) : []
      opts[:include_extras] ||= []
      opts[:action] = "create"
      body = RestClient::Payload.has_file?(self.attributes) ? self.serializable_hash(opts) : encode(opts)
    end

    
    def update(*args)
      body = setup_update_call(*args)
      # We can just ignore the response
      connection.put(element_path(self.id, prefix_options), body, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    def setup_update_call(*args)
      opts = args.extract_options!
      # When we create we should not include any blank attributes
      except = self.class.attribute_names - self.changed.symbolize_array
      changed_associations = self.changed.symbolize_array.select{|item| self.association?(item)}
      opts[:except] = opts[:except] ? opts[:except].concat(except).uniq.symbolize_array : except.symbolize_array
      opts[:include_blank_attributes] = self.include_all_attributes_on_update
      opts[:include_associations] = opts[:include_associations] ? opts[:include_associations].concat(args).concat(changed_associations).uniq : changed_associations.concat(args)
      opts[:include_extras] ||= []
      opts[:action] = "update"
      opts[:except] = [:id] if self.class.include_all_attributes_on_update
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
    
    include Scopes, Callbacks, Attributes, ModelErrors
    
  end
  
end
