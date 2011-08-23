require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Associations" do
  
  after(:all) do
    TestResource.reload_class_attributes
  end
  
  context "creating and testing for associations of various types" do
    
    it "should be be able to define an asociation using a method named after that association type" do
      TestResource.has_many :has_many_objects
      TestResource.has_many?(:has_many_objects).should be_true
    end
    
    it "should be able to define associations with different class names" do
      TestResource.has_many :test_name, :class_name => :has_many_objects
      TestResource.has_many?(:test_name).should be_true
      TestResource.has_many_class_name(:test_name).should eql("HasManyObject")
    end
    
    it "should be able to define multiple associations at the same time" do
      TestResource.has_many :has_many_objects, :other_has_many_objects
      TestResource.has_many?(:has_many_objects).should be_true
      TestResource.has_many?(:other_has_many_objects).should be_true
    end
    
    it "should be able to tell if something is an association via the association? method" do
      TestResource.belongs_to :belongs_to_object
      TestResource.association?(:belongs_to_object).should be_true
    end
    
    it "should be able to get the class name of an association via the association_class_name method" do
      TestResource.belongs_to :belongs_to_object
      TestResource.association_class_name(:belongs_to_object).should eql("BelongsToObject")
      TestResource.belongs_to :strange_name, :class_name => :belongs_to_object
      TestResource.association_class_name(:strange_name).should eql("BelongsToObject")
    end
  end
  
  context "creating and testing for scopes" do
    
    it "should be able to define scopes which require class names" do
      lambda {
        TestResource.scope :test_scope
      }.should raise_error
      TestResource.scope :test_scope, {:has_many_objects => "test"}
    end
    
    it "should be able to test if a scope exists" do
      TestResource.scope :test_scope, {:item => "test"}
      TestResource.scope?(:test_scope).should be_true
      TestResource.scope_attributes(:test_scope).should eql({"item" => "test"})
    end 
    
  end
  
  context "testing for scopes and associations on an instance" do
    
    it "should be able to define associations on a class and test for them on an instance" do
      TestResource.has_many :has_many_objects, :class_name => :other_has_many_objects
      tst = TestResource.new
      tst.has_many?(:has_many_objects).should be_true
      tst.has_many_class_name(:has_many_objects).should eql("OtherHasManyObject")
    end
    
    it "should be able to define scopes on a class and test for them on an instance" do
      TestResource.scope :has_many_objects, {:item => "test"}
      tst = TestResource.new
      tst.scope?(:has_many_objects).should be_true
      tst.scope_attributes(:has_many_objects).should eql({"item" => "test"})
    end
    
  end
  
  describe "Single Object Associations" do
    
    before(:all) do
      TestResource.related_objects[:scope].clear
    end
    
    after(:all) do
      TestResource.attribute_names.clear
    end
    
    it "should be able to create a SingleObjectProxy around a blank hash" do
      ap = Associations::SingleObjectProxy.new("TestResource", {})
      ap.remote_path.should be_blank
    end
    
    it "should be able to extract a service uri from the contents hash" do
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path"})
      ap.remote_path.should eql("/path")
    end
    
    it "should be able to recognize the attributes of an object and not make them scopes" do
      TestResource.known_attributes :test
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path", :test => "testval"})
      ap.scope?("test").should be_false
      ap.remote_path.should eql("/path")
    end
    
    it "should make all attributes except the service uri into scopes given the scopes_only option" do
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path", :test => {"testval" => true}, :scopes_only => true})
      ap.scope?("test").should be_true
      ap.remote_path.should eql("/path")
    end

    it "should pass the attributes that are not scopes and make them attributes of the object" do
      TestResource.known_attributes :test
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path", :test => "testval"})
      ap.internal_object.attributes.keys.should include("test")
    end
  end
  
  describe "Multi Object Associations" do

    before(:all) do
      TestResource.related_objects[:scope].clear
    end

    after(:each) do
      Associations::MultiObjectProxy.remote_path_element = :service_uri
    end

    describe "Loading settings" do

      context "Loading array contents" do

        it "should be able to load a blank array" do
          ap = Associations::MultiObjectProxy.new("TestResource",[])
          ap.remote_path.should be_nil
          ap.scopes.keys.should eql(["all"])
        end

        it "should be able to recognize a settings hash if it has a service_uri" do
          ap = Associations::MultiObjectProxy.new("TestResource",[{:service_uri => "/route"}])
          ap.remote_path.should eql("/route")
        end

        it "should be able to recognize a settings hash if it has a 'service_uri' with another preset name" do
          Associations::MultiObjectProxy.remote_path_element = :the_element
          ap = Associations::MultiObjectProxy.new("TestResource",[{:the_element => "/route"}])
          ap.remote_path.should eql("/route")
        end

      end

      context "Loading hash contents" do

        it "should not be able to load a hash without a 'service_uri'" do
          lambda {
            Associations::MultiObjectProxy.new("TestResource", {})
          }.should raise_error
        end

        it "should be able to recognize settings from a hash" do
          ap = Associations::MultiObjectProxy.new("TestResource", {:service_uri => "/route"})
          ap.remote_path.should eql("/route")
        end

        it "should recognize settings with differing 'service_uri' names" do
          Associations::MultiObjectProxy.remote_path_element = :the_element
          ap = Associations::MultiObjectProxy.new("TestResource",{:the_element => "/route"})
          ap.remote_path.should eql("/route")
        end
      end

      context "Defining scopes" do

        it "should define scopes based on the other keys in a settings hash" do
          ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
          [:scope1, :scope2].each{|s| ap.scopes.include?(s).should be_true }
        end

        it "should identify known scopes based on the scopes defined on the object it is a proxy to" do
          TestResource.scope :class_scope, "class_scope" => "true"
          ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
          [:scope1, :scope2, :class_scope].each{|s| ap.scopes.include?(s).should be_true}
        end

        it "scopes in the response should shadow class defined scopes" do
          TestResource.scope :scope1, "scope1" => "true"
          ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
          ap.scopes[:scope1].should eql({"scope1" => true})
        end
      end

    end

    describe "Selecting scopes" do

      it "should be able to change scopes" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
        ap.scope1.should be_a(Associations::RelationScope)
        ap.scope1.current_scope.scope1?.should be_true
      end

      it "should be able to chain scope calls together" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
        ap.scope1.scope2.current_scope.scope1_and_scope2?.should be_true
        ap.scope1.scope2.query_string.should eql("scope1=true&scope2=true")
      end
      
      it "should support scopes that contain underscores" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope_1 => {"scope_1" => true}, :scope_2 => {"scope_2" => true}}])
        ap.scope_1.scope_2.current_scope.scope_1_and_scope_2?.should be_true
      end
      
      it "should be able to return the current query string" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope_1 => {"scope_1" => true}, :scope_2 => {"scope_2" => true}}])
        ap.scope_1.scope_2.query_string.should eql("scope_1=true&scope_2=true")
      end
      
      it "should be able to substitute values into the scope query strings by passing a hash to the methods" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope_1 => {"scope_1" => true, :test_sub => false}, :scope_2 => {"scope_2" => true}}])
        obj = ap.scope_1(:test_sub => true).scope_2
        obj.query_string.should eql("scope_1=true&scope_2=true&test_sub=true")
      end
    end


  end
  
  describe "Loading and Caching loaded data" do
    
    context "Single Object" do
      
      it "should be able to load 'all'"
      
      it "should be able to load a scope"
      
      it "should be able to load a chain of scopes"
      
      it "should be able to load a chain of scopes with substitution"
      
      it "should proxy unknown methods to the object loading if it hasn't already"
      
      it "should only load each distinct set of scopes once"
      
    end
    
    context "Multi Object" do
      
      
      it "should be able to load 'all'"
      
      it "should be able to load a scope"
      
      it "should be able to load a chain of scopes"
      
      it "should be able to load a chain of scopes with substitution"
      
      it "should proxy unknown methods to the object array loading if it hasn't already"
      
      it "should only load each distinct set of scopes once"
      
    end
    
  end
  
end