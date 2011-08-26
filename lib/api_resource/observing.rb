module ApiResource
  
  module Observing
    
    extend ActiveSupport::Concern
    include ActiveModel::Observing
    
    # Redefine these methods to 
    included do
      %w( create save update destroy ).each do |method|
        alias_method_chain method, :observers
    end
    
    module InstanceMethods
      %w( create save update destroy ).each do |method|
        module_eval <<-EOE, __FILE__, __LINE__ + 1
          def #{method}_with_observers(*args)
            notify_observers(:before_#method)
            if result = #{method}_without_observers(*args)
              notify_observers(:after_#{method})
            end
            return result
          end
        EOE
      end
    end
    
  end
end