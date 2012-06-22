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
    
    def save_with_callbacks(*args)
      run_callbacks :save do
        save_without_callbacks(*args)
      end
    end
    
    def create_with_callbacks(*args)
      run_callbacks :create do
        create_without_callbacks(*args)
      end
    end
    
    def update_with_callbacks(*args)
      run_callbacks :update do
        update_without_callbacks(*args)
      end
    end
    
    def destroy_with_callbacks(*args)
      run_callbacks :destroy do
        destroy_without_callbacks(*args)
      end
    end
    
  end
  
end