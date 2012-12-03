require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Associations" do

  after(:all) do
    TestResource.reload_class_attributes
  end

  context "creating and testing for associations of various types" do

    it "should be able to give a list of all associations" do
      AllAssociations = Class.new(ApiResource::Base)
      AllAssociations.class_eval do
        has_many :has_many_objects
        belongs_to :belongs_to_object
        has_one :has_one_object
      end
      AllAssociations.association_names.sort.should eql(
        [:has_many_objects, :belongs_to_object, :has_one_object].sort
      )
      AllAssociations.new.association_names.sort.should eql [:has_many_objects, :belongs_to_object, :has_one_object].sort
    end

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

    it "should only define relationships for the given class - they should not cascade" do
      TestResource.belongs_to :belongs_to_object
      AnotherTestResource.association?(:belongs_to_object).should_not be_true
    end

    it "should have its relationship cascade when sub-classed after the relationship is defined" do
      TestResource.belongs_to :belongs_to_object
      class ChildTestResource2 < TestResource; end
      ChildTestResource2.association?(:belongs_to_object).should be true
    end

    context "Determining associated classes with a namespace" do

      it "should be able to find classes for associations that exist in the same module without a namespace" do
        TestMod::TestClass.belongs_to :test_association
        TestMod::TestClass.association_class_name(:test_association).should eql("TestMod::TestAssociation")
      end

      it "should be return a regular class name for a class defined at the root level" do
        TestMod::TestClass.belongs_to :belongs_to_object
        TestMod::TestClass.association_class_name(:belongs_to_object).should eql("BelongsToObject")
      end

      it "should work for a class name specified with a namespace module" do
        TestMod::TestClass.belongs_to :nonsense, :class_name => "TestMod::TestAssociation"
        TestMod::TestClass.association_class_name(:nonsense).should eql("TestMod::TestAssociation")
      end

      it "should work for nested module as well" do
        TestMod::InnerMod::InnerClass.belongs_to :test_association
        TestMod::InnerMod::InnerClass.association_class_name(:test_association).should eql("TestMod::TestAssociation")
      end

      it "should prefer to find classes within similar modules to ones in the root namespace" do
        TestMod::InnerMod::InnerClass.belongs_to :test_resource
        TestMod::InnerMod::InnerClass.association_class_name(:test_resource).should eql("TestMod::TestResource")
      end

      it "should be able to override into the root namespace by prefixing with ::" do
        TestMod::InnerMod::InnerClass.belongs_to :test_resource, :class_name => "::TestResource"
        TestMod::InnerMod::InnerClass.association_class_name(:test_resource).should eql("::TestResource")        
      end

    end


  end

  context "Remote Definitions" do

    before(:all) do
      TestResource.reload_class_attributes
    end

    it "should be able define an association remotely" do
      TestResource.belongs_to?(:belongs_to_object).should be true
      TestResource.new.belongs_to_object.klass.should eql BelongsToObject
    end

    it "should be able define an association remotely" do
      TestResource.belongs_to?(:custom_name).should be true
      TestResource.new.custom_name.klass.should eql BelongsToObject
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

    it "should not propagate scopes from one class to another" do

      Scope1Class = Class.new(ApiResource::Base) do
        scope :one, {:item => "test"}
      end

      Scope2Class = Class.new(ApiResource::Base) do
        scope :two, {:abc => "def"}
      end

      Scope1Class.scope?(:one).should be true
      Scope1Class.scope?(:two).should be false

      Scope2Class.scope?(:one).should be false
      Scope2Class.scope?(:two).should be true

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
      TestResource.reload_class_attributes
    end

    after(:all) do
      TestResource.reload_class_attributes
    end

    it "should return nil if its internal object is nil" do
      ap = Associations::SingleObjectProxy.new("TestResource", {})
      ap.instance_variable_set(:@internal_object, nil)
      ap.blank?.should be_true
    end

    it "should not throw an error on serializable hash if its internal object is nil" do
      ap = Associations::SingleObjectProxy.new("TestResource", {})
      ap.instance_variable_set(:@internal_object, nil)
      lambda {ap.serializable_hash}.should_not raise_error
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
      TestResource.define_attributes :test
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path", :test => "testval"})
      ap.scope?("test").should be_false
      ap.remote_path.should eql("/path")
    end

    it "should make all attributes except the service uri into scopes given the scopes_only option" do
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path", :test_scope => {"testval" => true}, :scopes_only => true})
      ap.scope?("test_scope").should be_true
      ap.remote_path.should eql("/path")
    end

    it "should pass the attributes that are not scopes and make them attributes of the object" do
      TestResource.define_attributes :test
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => "/path", :test => "testval"})
      ap.internal_object.attributes.keys.should include("test")
    end
  end

  describe "Multi Object Associations" do

    before(:all) do
      TestResource.related_objects[:scopes].clear
    end

    after(:each) do
      Associations::MultiObjectProxy.remote_path_element = :service_uri
    end

    describe "Loading settings" do

      context "Loading array contents" do

        it "should be able to load a blank array" do
          ap = Associations::MultiObjectProxy.new("TestResource",[])
          ap.remote_path.should be_nil
          ap.scopes.keys.should eql([])
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
            Associations::MultiObjectProxy.new("TestResource", {:hi => 3})
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

      before(:all) do
        ScopeResource.class_eval do
          scope :no_arg, {}
          scope :one_arg, {:id => :req}
          scope :one_array_arg, {:ids => :req}
          scope :two_args, {:page => :req, :per_page => :req}
          scope :opt_args, {:arg1 => :opt}
          scope :var_args, {:ids => :rest}
          scope :mix_args, {:id => :req, :vararg => :rest}
        end
      end

      it "should be able to query scopes on the current model" do
        ScopeResource.no_arg.to_query.should eql                "no_arg=true"
        # ScopeResource.one_arg(5).to_query.should eql            "one_arg[id]=5"
        # ScopeResource.one_array_arg([3, 5]).to_query.should eql "one_array_arg[ids][]=3&one_array_arg[ids][]=5"
        # ScopeResource.two_args(1, 20).to_query.should eql       "two_args[page]=1&two_args[per_page]=20"
        # ScopeResource.opt_arg.to_query.should eql               "opt_args=true"
        # ScopeResource.opt_args(3).to_query.should eql           "opt_args[arg1]=3"
        # ScopeResource.var_args(1, 2).to_query.should eql        "var_args[ids][]=1&var_args[ids][]=2"
        # ScopeResource.mix_args("a", {:opt1 => 1}, {:opt2 => 2}).to_query.should eql "mix_args[arg1]=a&mix_args[vararg][][opt1]=1&mix_arg[vararg][][opt2]=2"
      end

      it "should be able to change scopes" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
        ap.scope1.should be_a(Associations::RelationScope)
        ap.scope1.current_scope.scope1_scope?.should be_true
      end

      it "should be able to chain scope calls together" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope1 => {"scope1" => true}, :scope2 => {"scope2" => true}}])
        ap.scope1.scope2.current_scope.scope1_and_scope2_scope?.should be_true
        ap.scope1.scope2.to_query.should eql("scope1=true&scope2=true")
      end

      it "should support scopes that contain underscores" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope_1 => {"scope_1" => true}, :scope_2 => {"scope_2" => true}}])
        ap.scope_1.scope_2.current_scope.scope_1_and_scope_2_scope?.should be_true
      end

      it "should be able to return the current query string" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope_1 => {"scope_1" => true}, :scope_2 => {"scope_2" => true}}])
        ap.scope_1.scope_2.to_query.should eql("scope_1=true&scope_2=true")
      end

      it "should be able to substitute values into the scope query strings by passing a hash to the methods" do
        ap = Associations::MultiObjectProxy.new("TestResource", [{:service_uri => "/route", :scope_1 => {"scope_1" => true, :test_sub => false}, :scope_2 => {"scope_2" => true}}])
        obj = ap.scope_1(:test_sub => true).scope_2
        obj.to_query.should eql("scope_1=true&scope_2=true&test_sub=true")
      end
    end


  end

  describe "Loading and Caching loaded data" do

    context "Single Object" do

      before(:all) do
        TestResource.reload_class_attributes
      end

      it "should be able to force load an object" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :scopes_only => true})
        ap.loaded.should be_blank
        name = ap.name
        name.should_not be_blank
        ap.loaded.should_not be_blank
        # Make sure it isn't reloaded
        ap.name.should eql(name)
      end

      it "should be able to load a scope" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :scopes_only => true})
        ap.internal_object.active.should be_false
        ap.times_loaded.should eql(1)
        ap.active.should be_a Associations::RelationScope
        ap.active.name.should_not be_blank
        ap.times_loaded.should eql(2)
        ap.active.internal_object.active.should be_true
        # another check that the resource wasn't reloaded
        ap.times_loaded.should eql(2)       
      end

      it "should be able to load a chain of scopes" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :with_birthday => {:birthday => true}, :scopes_only => true})
        first = ap.active.with_birthday.id
        ap.with_birthday.active.id.should eql(first)
        ap.times_loaded.should eql(1)
        ap.active.with_birthday.birthday.should_not be_blank
      end

      it "should proxy unknown methods to the object loading if it hasn't already" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => false}, :with_birthday => {:birthday => true}, :scopes_only => true})
        ap.times_loaded.should eql(0)
        ap.id.should_not be_blank
        ap.times_loaded.should eql(1)
      end

      it "should load scopes with caching" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :scopes_only => true})
        ap.times_loaded.should eql(0)
        ap.active.expires_in(30).internal_object
        ap.active.expires_in(30).internal_object
        ap.times_loaded.should eql(1)
      end

      it "should check that ttl matches the expiration parameter" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :scopes_only => true})
        ap.active.expires_in(10).ttl.should eql(10)
      end

      it "should cache scopes when caching enabled" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => false}, :with_birthday => {:birthday => true}, :scopes_only => true})
        ApiResource.expects(:with_ttl).with(10)
        ap.active(:active => true, :expires_in => 10).internal_object
      end

      it "should only load each distinct set of scopes once" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => false}, :with_birthday => {:birthday => true}, :scopes_only => true})
        ap.times_loaded.should eql(0)
        ap.active.with_birthday.internal_object
        ap.active.with_birthday.internal_object
        ap.with_birthday.active.internal_object
        ap.times_loaded.should eql(1)
      end

      it "should be able to clear it's loading cache" do
        ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :with_birthday => {:birthday => true}, :scopes_only => true})
        ap.active.internal_object
        ap.times_loaded.should eql(1)
        ap.reload
        ap.active.internal_object
        ap.times_loaded.should eql(1)
      end

    end

    it "should be able to reload a single-object association" do
      ap = Associations::SingleObjectProxy.new("TestResource",{:service_uri => '/single_object_association', :active => {:active => true}, :scopes_only => true})

      old_name = ap.name

      str = "krdflkjsd"

      ap.name = str
      ap.name.should eql str
      ap.reload

      ap.name.should eql old_name
    end

    it "should be able to reload a multi-object association" do
      ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => false}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})

      old_name = ap.first.name

      str = "krdflkjsd"

      ap.first.name = str
      ap.first.name.should eql str

      ap.reload

      ap.first.name.should eql old_name
    end

    it "should propagate the scopes from the associated class" do

      ap = Associations::MultiObjectProxy.new(
        "TestResource", {:service_uri => "/multi_object_association"}
      )
      ap.scopes.should eql(TestResource.scopes)
      true
    end


    context "Multi Object" do

      it "should be able to load 'all'" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => false}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        results = ap.all
        results.size.should eql(5)
        results.first.active.should be_false
      end

      it "should be able to load a scope" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => false}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        results = ap.active.internal_object
        results.size.should eql(5)
        results.first.active.should be_true
      end

      it "should be able to load a chain of scopes" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => true}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        results = ap.active.with_birthday.internal_object
        results.first.active.should be_true
        results.first.birthday.should_not be_blank
      end

      it "should be able to load a chain of scopes with substitution" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => true}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        results = ap.inactive(:active => true).with_birthday.internal_object
        results.first.active.should be_true
        results.first.birthday.should_not be_blank
      end

      it "should proxy unknown methods to the object array loading if it hasn't already" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => true}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        ap.first.should be_a TestResource
        ap.active.first.should be_a TestResource
        ap.times_loaded.should eql(2)
      end

      it "should only load each distinct set of scopes once" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => true}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        ap.first
        ap.active.first
        ap.times_loaded.should eql(2)
        ap.active.first
        ap.times_loaded.should eql(2)
        ap.active.with_birthday.first
        ap.with_birthday.active.first
        ap.times_loaded.should eql(3)
      end

      it "should be able to clear it's loading cache" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => true}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        ap.active.first
        ap.times_loaded.should eql(1)
        ap.reload
        ap.active.first
        ap.times_loaded.should eql(1)
      end

      it "should be enumerable" do
        ap = Associations::MultiObjectProxy.new("TestResource",{:service_uri => '/multi_object_association', :active => {:active => true}, :inactive => {:active => false}, :with_birthday => {:birthday => true}})
        ap.each do |tr|
          tr.name.should_not be_blank
        end
      end

    end

    context "Scopes" do

      before(:all) do
        TestResource.reload_class_attributes
      end

      it "should define class methods for the known scopes" do
        TestResource.scopes.each do |key, _|
          TestResource.should respond_to key
        end
      end

      it "should return a ResourceScope when calling any scope on a class" do
        TestResource.send(TestResource.scopes.first.first.to_sym).should be_a Associations::ResourceScope
      end

      it "should be able to chain scopes" do
        scp = TestResource.active.paginate
        scp.should be_a Associations::ResourceScope
        scp.to_query.should eql("active=true&paginate=true")
      end

      it "should load when calling all" do
        TestResource.active.should respond_to :all
        TestResource.active.should respond_to :internal_object
        results = TestResource.active.all
        results.should be_a Array
        results.size.should eql(5)
        results.each do |res|
          res.should be_a TestResource
        end
      end

      it "should load when calling an enumerable method or an array method" do
        TestResource.active.each do |result|
          result.should be_a TestResource
        end
      end


    end

    context "Assigning Data" do
      context "Single Object Association" do
        before(:all) do
          TestResource.has_one(:has_one_object)
          TestResource.belongs_to(:belongs_to_object)
        end
        after(:all) do
          TestResource.reload_class_attributes
        end

        it "should assign associations to the correct type on initialization" do
          #binding.pry
          tr = TestResource.new(:has_one_object => {:name => "Dan"}, :belongs_to_object => {:name => "Dan"})

          tr.has_one_object.internal_object.should be_instance_of HasOneObject
          tr.belongs_to_object.internal_object.should be_instance_of BelongsToObject

        end

        it "should assign associations to the correct type when setting attributes directly" do
          tr = TestResource.new()
          tr.has_one_object = {:name => "Dan"}
          tr.belongs_to_object = {:name => "Dan"} 

          tr.has_one_object.internal_object.should be_instance_of HasOneObject
          tr.belongs_to_object.internal_object.should be_instance_of BelongsToObject
        end

        it "should be able to reload a single-object association" do
          ApiResource::Associations::SingleObjectProxy.any_instance.stubs(:remote_path => "/has_one_objects")
          HasOneObject.connection.stubs(:get => nil)

          tr = TestResource.new()

          tr.has_one_object = {:color => "Blue"}

          tr.has_one_object.reload
          tr.has_one_object.instance_variable_get(:@internal_object).should be_blank
        end

      end

      context "Multi Object Association" do
        before(:all) do
          TestResource.has_many(:has_many_objects)
        end
        after(:all) do
          TestResource.reload_class_attributes
        end

        it "should assign associations to the correct type on initialization" do
          tr = TestResource.new(:has_many_objects => [{:name => "Dan"}])
          tr.has_many_objects.internal_object.first.should be_instance_of HasManyObject

        end

        it "should assign associations to the correct type when setting attributes directly" do
          tr = TestResource.new()
          tr.has_many_objects = [{:name => "Dan"}]
          tr.has_many_objects.internal_object.first.should be_instance_of HasManyObject
        end

        it "should be able to reload a multi-object association" do
          ApiResource::Associations::MultiObjectProxy.any_instance.stubs(:remote_path => "/has_many_objects")
          ApiResource::Connection.any_instance.stubs(:get => [])

          tr = TestResource.new(:has_many_objects => [{:color => "blue"}])

          tr.has_many_objects.reload

          tr.has_many_objects.should be_blank
        end

      end

      context "ActiveModel" do
        before(:all) do
          require 'active_record'
          db_path = File.expand_path(File.dirname(__FILE__) + "/../tmp/api_resource_test_db.sqlite")
          ActiveRecord::Base.establish_connection({"adapter" => "sqlite3", "database" => db_path})
          ActiveRecord::Base.connection.create_table(:test_ars, :force => true) do |t|
            t.integer(:test_resource_id)
          end
          ApiResource::Associations.activate_active_record
          TestAR = Class.new(ActiveRecord::Base)
          TestAR.class_eval do 
            belongs_to_remote :my_favorite_thing, :class_name => "TestClassYay"
          end
        end
        it "should define remote association types for AR" do
          [:has_many_remote, :belongs_to_remote, :has_one_remote].each do |assoc|
            ActiveRecord::Base.singleton_methods.should include assoc
          end
        end
        it "should add remote associations to related objects" do
          TestAR.related_objects.should eql({"has_many_remote"=>{}, "belongs_to_remote"=>{"my_favorite_thing"=>"TestClassYay"}, "has_one_remote"=>{}, "scopes"=>{}})
        end
        context "Not Overriding Scopes" do
          it "should not override scopes, which would raise an error with lambda-style scopes" do
            lambda {
              TestAR.class_eval do
                scope :my_favorite_scope, lambda {
                  joins(:my_test)
                }
              end
            }.should_not raise_error
          end
        end
        context "Belongs To" do
          before(:all) do
            TestAR.class_eval do
              belongs_to_remote :test_resource
            end
          end
          it "should attempt to load a single remote object for a belongs_to relationship" do
            tar = TestAR.new
            tar.stubs(:test_resource_id).returns(1)
            TestResource.connection.expects(:get).with("/test_resources/1.json").once.returns({"name" => "testing"})
            # load the test resource
            tar.test_resource.name.should eql "testing"
          end
        end
        context "Has One" do
          before(:all) do
            TestAR.class_eval do
              has_one_remote :test_resource
            end
          end
          it "should attempt to load a single remote object for a has_one relationship" do
            tar = TestAR.new
            tar.stubs(:id).returns(1)
            TestResource.connection.expects(:get).with("/test_resources.json?test_ar_id=1").once.returns([{"name" => "testing"}])
            # load the test resource
            tar.test_resource.name.should eql "testing"
          end
        end
        context "Has Many" do
          before(:all) do
            TestAR.class_eval do
              has_many_remote :has_many_objects
            end
          end
          it "should attempt to load a collection of remote objects for a has_many relationship" do
            tar = TestAR.new
            tar.stubs(:id).returns(1)
            HasManyObject.connection.expects(:get).with("/has_many_objects.json?test_ar_id=1").once.returns([{"name" => "testing"}])
            # load the test resource
            tar.has_many_objects.first.name.should eql "testing"
          end
        end
        context "Has Many Through" do
          before(:all) do       
            TestAR.class_eval do 
              self.extend ApiResource::Associations::HasManyThroughRemoteObjectProxy
              has_many :test_throughs
              has_many_through_remote(:belongs_to_objects, :through => :test_throughs)
            end
          end
          it "should attempt to load a collection of remote objects for a has_many_through relationship" do
            tar = TestAR.new
            through_test_resource_1 = TestThrough.new
            through_test_resource_2 = TestThrough.new
            belongs_to_object_1 = BelongsToObject.new
            belongs_to_object_2 = BelongsToObject.new
            tar.expects(:test_throughs).returns([through_test_resource_1, through_test_resource_2])
            through_test_resource_1.expects(:belongs_to_object).returns([belongs_to_object_1])
            through_test_resource_2.expects(:belongs_to_object).returns([belongs_to_object_2])

            tar.belongs_to_objects.should eql [belongs_to_object_1, belongs_to_object_2]
          end

        end
      end
    end
  end
end
