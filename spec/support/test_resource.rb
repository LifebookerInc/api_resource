class TestResource < ApiResource::Base
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