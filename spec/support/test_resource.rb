class TestResource < ApiResource::Base
end

module MyMod
  def abc
    puts "HI"
  end
end

class LocalResource < ApiResource::Local
  include MyMod
end

class ChildTestResource < TestResource
end

class AnotherTestResource < ApiResource::Base
  
end

class HasManyObject < ApiResource::Base
end

class BelongsToObject < ApiResource::Base
end

class HasOneObject < ApiResource::Base
end

class ErrorResource < ApiResource::Base
  
end

class ErrorFullMessageResource < ApiResource::Base
  
end

module TestMod
  
  module InnerMod
    
    class InnerClass < ApiResource::Base
   
    end
    
  end
  
  class TestClass < ApiResource::Base
    
  end
  
  class TestAssociation < ApiResource::Base
    
  end
  
  class TestResource < ApiResource::Base
  
  end
  
end