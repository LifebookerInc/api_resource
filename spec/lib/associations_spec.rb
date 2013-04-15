require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

include ApiResource

describe "Associations" do

  before(:each) do
    TestResource.reload_class_attributes
  end

  let(:ap) do
    Associations::SingleObjectProxy.new(
      "TestResource", 
      HasManyObject.new, {
        :service_uri => '/single_object_association'
      }
    )
  end

  context "Comparison" do

    context "&group_by" do

      it "should allow grouping by resources with the same id" do

        tr1 = TestResource.find(1)
        tr2 = TestResource.find(1)


        tr1.has_one_object
        tr2.has_one_object

        [tr1, tr2].group_by(&:has_one_object).keys.length.should be 1
      end

    end

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

    it "should be able to return the name of the foreign key field field for the association" do
      TestResource.belongs_to :belongs_to_object
      TestResource.has_many :has_many_objects
      TestResource.association_foreign_key_field(:belongs_to_object).should eql(:belongs_to_object_id)
      TestResource.association_foreign_key_field(:has_many_objects).should eql(:has_many_object_ids)
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
      ap = Associations::SingleObjectProxy.new(
        "TestResource", 
        HasManyObject.new, {
          :service_uri => '/path'
        }
      )
      ap.remote_path.should eql("/path")
    end

    it "should be able to recognize the attributes of an object 
      and not make them scopes" do
      
      TestResource.define_attributes :test
      ap = Associations::SingleObjectProxy.new(
        "TestResource", 
        HasManyObject.new, {
          :service_uri => '/path',
          :test => "testval"
        }
      )
      ap.scope?("test").should be_false
      ap.test.should eql("testval")

    end

    it "should include the foreign_key_id when saving" do
      tr = TestResource.new
      tr.belongs_to_object_id = 4
      hsh = tr.serializable_hash
      hsh[:belongs_to_object_id].should eql(4)
    end

    it "should serialize the foreign_key_id when saving if it is updated" do
      TestResource.connection
      tr = TestResource.find(1)
      tr.belongs_to_object_id = 5
      hsh = tr.serializable_hash
      hsh[:belongs_to_object_id].should eql(5)
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
          ap = Associations::MultiObjectProxy.new(
            "TestResource",
            BelongsToObject.new
          )
          ap.remote_path.should be_nil
        end

        it "should be able to recognize a settings hash if it has a service_uri" do
          ap = Associations::MultiObjectProxy.new(
            "TestResource",
            BelongsToObject.new,
            [{:service_uri => "/route"}]
          )
          ap.remote_path.should eql("/route")
        end

        it "should be able to recognize a settings hash if it has a 'service_uri' with another preset name" do
          Associations::MultiObjectProxy.remote_path_element = :the_element
          ap = Associations::MultiObjectProxy.new(
            "TestResource",
            BelongsToObject.new,
            [{:the_element => "/route"}]
          )
          ap.remote_path.should eql("/route")
        end

      end

      context "Loading hash contents" do
        it "should not be able to load a hash without a 'service_uri'" do
          lambda {
            Associations::MultiObjectProxy.new(
              "TestResource", 
              BelongsToObject,
              {:hi => 3}
            )
          }.should raise_error
        end

        it "should be able to recognize settings from a hash" do
          ap = Associations::MultiObjectProxy.new(
            "TestResource", 
            BelongsToObject,
            {:service_uri => "/route"}
          )
          ap.remote_path.should eql("/route")
        end

        it "should be able to recognize settings from a hash as a string" do
          ap = Associations::MultiObjectProxy.new(
            "TestResource", 
            BelongsToObject,
            {"service_uri" => "/route"}
          )
          ap.remote_path.should eql("/route")
        end

        it "should recognize settings with differing 'service_uri' names" do
          Associations::MultiObjectProxy.remote_path_element = :the_element
          ap = Associations::MultiObjectProxy.new(
            "TestResource", 
            BelongsToObject,
            {:the_element => "/route"}
          )
          ap.remote_path.should eql("/route")
        end

        it "should include the foreign_key_id when saving" do
          tr = TestResource.new.tap do |tr|
            tr.stubs(:id => 123)
          end
          tr.has_many_object_ids = [4]
          hsh = tr.serializable_hash
          hsh[:has_many_object_ids].should eql([4])
        end

        it "should handle loading attributes from the remote" do
          tr = TestResource.instantiate_record({:has_many_object_ids => [3]})
          tr.has_many_object_ids.should eql([3])
        end

        it "should not try to load if the foreign key is nil" do
          TestResource.connection.expects(:get).returns(:id => 1, :belongs_to_object_id => nil)
          tr = TestResource.find(1)
          tr.id.should eql(1)
          tr.belongs_to_object_id.should be_nil
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
        ScopeResource.no_arg.to_query.should eql(
          "no_arg=true"
        )
        ScopeResource.one_arg(5).to_query.should eql(
          "one_arg[id]=5"
        )
        ScopeResource.one_array_arg([3, 5]).to_query.should eql(
          "one_array_arg[ids][]=3&one_array_arg[ids][]=5"
        )
        ScopeResource.two_args(1, 20).to_query.should eql(
          "two_args[page]=1&two_args[per_page]=20"
        )
        $DEB = true
        ScopeResource.opt_args.to_query.should eql(
          "opt_args=true"
        )
        ScopeResource.opt_args(3).to_query.should eql(
          "opt_args[arg1]=3"
        )
        ScopeResource.var_args(1, 2).to_query.should eql(
          "var_args[ids][]=1&var_args[ids][]=2"
        )
        args = ["a", {:opt1 => 1}, {:opt2 => 2}]
        ScopeResource.mix_args(*args).to_query.should eql(
          "mix_args[id]=a&mix_args[vararg][][opt1]=1&mix_args[vararg][][opt2]=2"
        )
      end
    end


  end

  describe "Loading and Caching loaded data" do


    before(:each) do
      # Clear the cache to prevent any funny business
      ApiResource.cache(true)
    end

    context "Single Object" do

      before(:all) do
        TestResource.reload_class_attributes
      end

      it "should be able to force load an object" do
        ap.should_not be_loaded
        name = ap.name
        name.should_not be_blank
        ap.should be_loaded
        # Make sure it isn't reloaded
        ap.name.should eql(name)
      end


      it "should proxy unknown methods to the object loading if it hasn't already" do
        ap = Associations::SingleObjectProxy.new(
          "TestResource", 
          HasManyObject.new, {
            :service_uri => '/single_object_association'
          }
        )
        ap.should_not be_loaded
        ap.id.should_not be_blank
        ap.should be_loaded
      end

      it "should load scopes with caching" do
        ap = Associations::SingleObjectProxy.new(
          "TestResource", 
          HasManyObject.new, {
            :service_uri => '/single_object_association'
          }
        )
        ap.should_not be_loaded
        ap.active.expires_in(30).internal_object

        # should only be called once
        TestResource.connection.expects(:request).never
        ap.active.expires_in(30).internal_object
      end

      it "should check that ttl matches the expiration parameter" do
       ap = Associations::SingleObjectProxy.new(
          "TestResource", 
          HasManyObject.new, {
            :service_uri => '/single_object_association'
          }
        )
        ap.active.expires_in(10).ttl.should eql(10)
      end

      it "should cache scopes when caching enabled" do
        ap = Associations::SingleObjectProxy.new(
          "TestResource", 
          HasManyObject.new, {
            :service_uri => '/single_object_association'
          }
        )
        ap.active(:expires_in => 10).internal_object
      end

      it "should be able to clear it's loading cache" do
        ap = Associations::SingleObjectProxy.new(
          "TestResource", 
          HasManyObject.new, {
            :service_uri => '/single_object_association'
          }
        )
        active = ap.active

        active.internal_object
        active.should be_loaded
        active.reload
        active.should_not be_loaded
        active.internal_object
        active.should be_loaded
      end

    end

    it "should be able to reload a single-object association" do
      ap = Associations::SingleObjectProxy.new(
        "TestResource", 
        HasManyObject.new, {
          :service_uri => '/single_object_association'
        }
      )

      old_name = ap.name

      str = "krdflkjsd"

      ap.name = str

      ap.name.should eql str
      ap.reload

      ap.name.should eql old_name
    end

    it "should be able to reload a multi-object association" do
      
      ap = Associations::MultiObjectProxy.new(
        "TestResource", 
        BelongsToObject.new, {
          :service_uri => '/multi_object_association'
        }
      )

      old_name = ap.first.name

      str = "krdflkjsd"

      ap.first.name = str
      ap.first.name.should eql str

      ap.reload

      ap.first.name.should eql old_name
    end

    context "Multi Object" do

      it "should be able to load 'all'" do
        ap = Associations::MultiObjectProxy.new(
          "TestResource", 
          BelongsToObject.new, {
            :service_uri => '/multi_object_association'
          }
        )
        results = ap.all
        results.size.should eql(5)
        results.first.is_active?.should be_false
      end

      it "should be able to load a scope" do
        ap = Associations::MultiObjectProxy.new(
          "TestResource", 
          BelongsToObject.new, {
            :service_uri => '/multi_object_association'
          }
        )
        results = ap.active
        results.size.should eql(5)
        record = results.first
        record.is_active.should be_true
      end

      it "should be able to load a chain of scopes" do
        ap = Associations::MultiObjectProxy.new(
          "TestResource", 
          BelongsToObject.new, {
            :service_uri => '/multi_object_association'
          }
        )
        results = ap.active.birthday(Date.today)
        results.first.is_active.should be_true
        results.first.bday.should_not be_blank
      end


      it "should be able to clear it's loading cache" do

        ap = Associations::MultiObjectProxy.new(
          "TestResource", 
          BelongsToObject.new, {
            :service_uri => '/multi_object_association'
          }
        )
        active = ap.active

        active.internal_object
        active.should be_loaded
        active.reload
        active.should_not be_loaded
        active.internal_object
        active.should be_loaded
      end

      it "should be enumerable" do
        ap = Associations::MultiObjectProxy.new(
          "TestResource", 
          BelongsToObject.new, {
            :service_uri => '/multi_object_association'
          }
        )
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

      it "should return a ScopeCondition when calling any scope on a class" do
        TestResource.send(TestResource.scopes.first.first.to_sym).should be_a Conditions::ScopeCondition
      end

      it "should be able to chain scopes" do
        scp = TestResource.active.paginate(20, 1)
        scp.should be_a Conditions::ScopeCondition
        scp.to_query.should eql(
          "active=true&paginate[current_page]=1&paginate[per_page]=20"
        )
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
          HasManyObject.reload_class_attributes
          BelongsToObject.reload_class_attributes
          HasOneObject.reload_class_attributes
        end
        after(:all) do
          TestResource.reload_class_attributes
        end

        it "should assign associations to the correct 
          type on initialization" do
          
          tr = TestResource.new(
            :has_one_object => {:color => "Blue"}, 
            :belongs_to_object => {:zip => "11201"},
            :has_many_objects => [{:name => "Dan"}]
          )

          tr.has_one_object.internal_object.should be_instance_of(
            HasOneObject
          )
          tr.has_one_object.color.should eql("Blue")

          tr.belongs_to_object.internal_object.should be_instance_of(
            BelongsToObject
          )
          tr.belongs_to_object.zip.should eql("11201")


          tr.has_many_objects.internal_object.first.should be_instance_of(
            HasManyObject
          )
          tr.has_many_objects.first.name.should eql("Dan")

        end

        it "should assign associations to the correct type when setting attributes directly" do
          tr = TestResource.new()
          tr.has_one_object = {:name => "Dan"}
          tr.belongs_to_object = {:name => "Dan"} 

          tr.has_one_object.internal_object.should be_instance_of HasOneObject
          tr.belongs_to_object.internal_object.should be_instance_of BelongsToObject
        end

        it "should be able to reload a single-object association" do
          
          tr = TestResource.new()
          tr.has_one_object = {:color => "Blue"}

          tr.has_one_object.reload
          tr.has_one_object.should be_nil
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
          
          # do this to load the resource definition
          TestResource.reload_resource_definition
          HasManyObject.reload_resource_definition

          tr = TestResource.new
          tr.has_many_objects = [{:name => "Dan"}]

          tr.has_many_objects.reload
          tr.has_many_objects.should be_blank
        end

        it "should be able to override service_uri for a 
          multi-object association" do

          tr = TestResource.new
          tr.has_many_objects = [{:service_uri => "/a/b/c"}]

          tr.has_many_objects.remote_path.should eql("/a/b/c")

        end

        it "should be able to override service_uri for a multi-object 
          association when loaded with instantiate_record" do

          tr = TestResource.instantiate_record(
            :has_many_objects => [{:service_uri => "/a/b/c"}]
          )

          tr.has_many_objects.remote_path.should eql("/a/b/c")
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
          HasManyObject.reload_resource_definition
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
              has_one_remote :other_test_resource, 
                :class_name => "TestResource"
            end
          end
          it "should attempt to load a single remote object for a has_one relationship" do
            tar = TestAR.new
            tar.stubs(:id).returns(1)
            TestResource.connection.expects(:get)
              .with("/test_resources.json?test_ar_id=1")
              .returns([{"name" => "testing"}])
            # load the test resource
            tar.test_resource.name.should eql "testing"
          end

          it "should use its object's primary_key as the _id method" do
            tar = TestAR.new
            tar.stubs(:id).returns(1)
            TestResource.connection.expects(:get)
              .with("/test_resources.json?test_ar_id=1")
              .returns([{"name" => "testing", "id" => 14}])
            # load the test resource
            tar.other_test_resource_id.should eql(14)
          end

          it "should handle mising objects in its _id method" do
            tar = TestAR.new
            tar.stubs(:id).returns(1)
            TestResource.connection.expects(:get)
              .with("/test_resources.json?test_ar_id=1")
              .returns([])
            # load the test resource
            tar.other_test_resource_id.should be_nil
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
            HasManyObject.load_resource_definition
            HasManyObject.connection.expects(:get).with("/has_many_objects.json?test_ar_id=1").once.returns(
                [{"name" => "testing", "id" => 22}]
              )
            # load the test resource
            tar.has_many_objects.internal_object
            tar.has_many_objects.first.name.should eql "testing"
            tar.has_many_object_ids.should eql([22])
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
