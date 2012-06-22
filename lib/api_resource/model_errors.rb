module ApiResource
  
  class Errors < ::ActiveModel::Errors
    
    def from_array(messages, save_cache = false)
      clear unless save_cache
      humanized_attributes = @base.attributes.keys.inject({}) { |h, attr_name| h.update(attr_name.humanize => attr_name) }
      messages.each do |message|
        attr_message = humanized_attributes.keys.detect do |attr_name|
          if message[0,attr_name.size + 1] == "#{attr_name} "
            add humanized_attributes[attr_name], message[(attr_name.size + 1)..-1]
          end
        end
      end
    end
    
    def from_hash(messages, save_cache = false)
      clear unless save_cache
      messages.each do |attr, message_array|
        message_array.each do |message|
          add attr, message
        end
      end
    end

  end
  
  module ModelErrors
  
    extend ActiveSupport::Concern
    include ActiveModel::Validations
    
    included do
      # this is required here because this module will be above Base in the inheritance chain
      alias_method_chain :save, :validations
    end
    
    def save_with_validations(*args)
      # we want to leave the original intact
      options = args.clone.extract_options!
      
      perform_validation = options.blank? ? true : options[:validate]
      
      @remote_errors = nil
      if perform_validation && valid? || !perform_validation
        save_without_validations(*args)
        true
      else
        false
      end
    rescue ApiResource::UnprocessableEntity => error
      @remote_errors = error
      load_remote_errors(@remote_errors, true)
      false
    end
    
    def load_remote_errors(remote_errors, save_cache = false)
      error_data = self.class.format.decode(remote_errors.response.body)['errors'] || {}
      if error_data.is_a?(Hash)
        self.errors.from_hash(error_data)
      elsif error_data.is_a?(Array)
        self.errors.from_array(error_data)
      else
        raise Exception.new
      end
    rescue Exception
      raise "Invalid response for invalid object: expected an array or hash got #{remote_errors}"
    end
    
    # This method runs any local validations but not remote ones
    def valid?
      super
      errors.empty?
    end
    
    def errors
      @errors ||= ApiResource::Errors.new(self)
    end
    
  end
  
end