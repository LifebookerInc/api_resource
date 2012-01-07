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
    
    # logger
    def self.logger
      return @logger if @logger
      @logger = Log4r::Logger.new("api_resource")
      @logger.outputters = [Log4r::StdoutOutputter.new('console')]
      @logger.level = Log4r::INFO
      @logger
    end
  end
end