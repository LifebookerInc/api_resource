require 'api_resource'
require 'rails'

module ApiResource
  
  class Railtie < ::Rails::Railtie
    
    config.api_resource = ActiveSupport::OrderedOptions.new
    
    initializer "api_resource.set_configs" do |app|
      app.config.api_resource.each do |k,v|
        ApiResource::Base.send "#{k}=", v
      end
    end
    
  end
  
end