module ApiResource
  class Local < Base
    # nothing to do here
    def self.set_class_attributes_upon_load
      true
    end
    # no definition to load
    def self.load_resource_definition
      true
    end
    # shouldn't do anything here either - 
    def self.reload_resource_definition
      true
    end
  end
end