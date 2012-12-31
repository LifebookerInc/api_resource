module ApiResource
  
  module Observing
    
    extend ActiveSupport::Concern
    include ActiveModel::Observing
    
    # Redefine these methods to 
    included do

      %w( create save update destroy ).each do |method|
        alias_method_chain method, :observers
      end
    end
    
    %w( create save update destroy ).each do |method|
      module_eval <<-EOE, __FILE__, __LINE__ + 1
        def #{method}_with_observers(*args)
          unless notify_observers(:before_#{method})
            return false
          end
          result = #{method}_without_observers(*args)
          notify_observers(:after_#{method}) if result
          return result
        end
      EOE
    end

    # also need to override notify_observers to return false if
    # ANY of the observers return false, however it will ALWAYS run them all
    def notify_observers(method)
      self.class.observer_instances.inject(true) do |accum, obs|
        obs.update(method, self) && accum
      end
    end
    
  end

  # Blank class here for ease of use, might need
  # some methods some day
  class Observer < ActiveModel::Observer
  end
end