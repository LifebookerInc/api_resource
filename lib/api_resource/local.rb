module ApiResource
  class Local < Base
    # nothing to do here
    def self.set_class_attributes_upon_load
      true
    end
    # shouldn't do anything here either - 
    def self.reload_class_attributes
      true
    end
  end
end