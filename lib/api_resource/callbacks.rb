module ApiResource
  
  module Callbacks
    
    extend ActiveSupport::Concern
    
    included do
      
      extend ActiveModel::Callbacks
      
      define_model_callbacks :save, :create, :update, :destroy
      
      [:save, :create, :update, :destroy].each do |action|
        alias_method_chain action, :callbacks
      end
      
    end
    
    module InstanceMethods
      
      def save_with_callbacks(*args)
        _run_save_callbacks do
          save_without_callbacks(*args)
        end
      end
      
      def create_with_callbacks(*args)
        _run_create_callbacks do
          create_without_callbacks(*args)
        end
      end
      
      def update_with_callbacks(*args)
        _run_update_callbacks do
          update_without_callbacks(*args)
        end
      end
      
      def destroy_with_callbacks(*args)
        _run_destroy_callbacks do
          destroy_without_callbacks(*args)
        end
      end
      
    end
    
  end
  
end