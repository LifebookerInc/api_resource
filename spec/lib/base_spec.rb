require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'json'

include ApiResource

describe "Base" do
  
  after(:all) do
    TestResource.reload_class_attributes
  end
  
  describe "Loading data from a hash" do
    
    describe "Determining Attributes, Scopes, and Associations from the server" do

      it "should determine it's attributes when the class loads" do
        tst = TestResource.new
        tst.attribute?(:name).should be_true
        tst.attribute?(:age).should be_true
      end
      
      it "should determine it's associations when the class loads" do
        tst = TestResource.new
        tst.association?(:has_many_objects).should be_true
        tst.association?(:belongs_to_object).should be_true
      end
      
      it "should be able to determine scopes when the class loads" do
        tst = TestResource.new
        tst.scope?(:paginate).should be_true
        tst.scope?(:active).should be_true
      end

    end
    context "Attributes" do
      before(:all) do
        TestResource.define_attributes :attr1, :attr2
        TestResource.define_protected_attributes :attr3
      end
    
      it "should set attributes for the data loaded from a hash" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2"})
        tst.attr1?.should be_true
        tst.attr1.should eql("attr1")
        tst.attr1 = "test"
        tst.attr1.should eql("test")
      end
    
      it "should create protected attributes for unknown attributes trying to be loaded" do
        tst = TestResource.new({:attr1 => "attr1", :attr3 => "attr3"})
        tst.attr3?.should be_true
        tst.attr3.should eql("attr3")
        lambda {
          tst.attr3 = "test"
        }.should raise_error
      end
    end
    
    context "Associations" do
      before(:all) do
        TestResource.has_many :has_many_objects
        TestResource.has_one :has_one_object
        TestResource.belongs_to :belongs_to_object
      end
      
      after(:all) do
        TestResource.related_objects.each do |key,val|
          val.clear
        end
      end
      
      context "MultiObjectProxy" do
      
        it "should create a MultiObjectProxy for has_many associations" do
          tst = TestResource.new({:has_many_objects => []})
          tst.has_many_objects.should be_a(Associations::MultiObjectProxy)
        end
        
        it "should throw an error if a has many association is not nil or an array or a hash" do
          TestResource.new({:has_many_objects => nil})
          lambda {
            TestResource.new({:has_many_objects => "invalid"})
          }.should raise_error
        end
        
        it "should properly load the data from the provided array or hash" do
          tst = TestResource.new({:has_many_objects => [{:service_uri => '/path'}]})
          tst.has_many_objects.remote_path.should eql('/path')
          tst = TestResource.new({:has_many_objects => {:service_uri => '/path'}})
          tst.has_many_objects.remote_path.should eql('/path')
        end
        
      end
      
      context "SingleObjectProxy" do
        
        it "should create a SingleObjectProxy for belongs to and has_one associations" do
          tst = TestResource.new(:belongs_to_object => {}, :has_one_object => {})
          tst.belongs_to_object.should be_a(Associations::SingleObjectProxy)
          tst.has_one_object.should be_a(Associations::SingleObjectProxy)
        end
        
        it "should throw an error if a belongs_to or has_many association is not a hash or nil" do
          lambda {
            TestResource.new(:belongs_to_object => [])
          }.should raise_error
          lambda {
            TestResource.new(:has_one_object => [])
          }.should raise_error
        end
        
        it "should properly load data from the provided hash" do
          tst = TestResource.new(:has_one_object => {:service_uri => "/path"})
          tst.has_one_object.remote_path.should eql('/path')
        end
        
      end
    end
  end
    
  describe "Request parameters and paths" do
    
    after(:each) do
      TestResource.element_name = TestResource.model_name.element
      TestResource.collection_name = TestResource.element_name.to_s.pluralize
    end
    
    it "should set the element name and collection name by default" do
      TestResource.element_name.should eql("test_resource")
      TestResource.collection_name.should eql("test_resources")
    end
    
    it "should be able to set the element and collection names to anything" do
      TestResource.element_name = "element"
      TestResource.collection_name = "elements"
      TestResource.element_name.should eql("element")
      TestResource.collection_name.should eql("elements")
    end
    
    it "should propery generate collection paths and element paths with the new names and the default format json" do
      TestResource.element_name = "element"
      TestResource.collection_name = "elements"
      TestResource.new_element_path.should eql("/elements/new.json")
      TestResource.collection_path.should eql("/elements.json")
      TestResource.element_path(1).should eql("/elements/1.json")
      TestResource.element_path(1, :active => true).should eql("/elements/1.json?active=true")
    end
    
    it "should be able to set the format" do
      TestResource.format.extension.to_sym.should eql(:json)
      TestResource.format = :xml
      TestResource.format.extension.to_sym.should eql(:xml)
      TestResource.format = :json
    end
    
    it "should be able to set an http timeout" do
      TestResource.timeout = 5
      TestResource.timeout.should eql(5)
      TestResource.connection.timeout.should eql(5)
    end
       
  end
  
  describe "Serialization" do
    
    before(:all) do
      TestResource.has_many :has_many_objects
      TestResource.define_attributes :attr1, :attr2
      TestResource.include_root_in_json = true
    end
    
    before(:each) do
      TestResource.include_root_in_json = false
    end
    
    context "JSON" do
      it "should be able to serialize itself without the root" do
        TestResource.include_root_in_json = false
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2"})
        hash = JSON.parse(tst.to_json)
        hash["attr1"].should eql("attr1")
        hash["attr2"].should eql("attr2")
      end
      
      it "should be able to serialize itself with the root" do
        TestResource.include_root_in_json = true
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2"})
        hash = JSON.parse(tst.to_json)
        hash["test_resource"].should_not be_nil
      end
      
      it "should not include associations by default" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2", :has_many_objects => []})
        hash = JSON.parse(tst.to_json)
        hash["has_many_objects"].should be_nil
      end
      
      it "should include associations passed given in the include_associations array" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2", :has_many_objects => []})
        hash = JSON.parse(tst.to_json(:include_associations => [:has_many_objects]))
        hash["has_many_objects"].should_not be_nil
      end
      
      it "should not include unknown attributes unless they are passed in via the include_extras array" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2", :attr3 => "attr3"})
        hash = JSON.parse(tst.to_json)
        hash["attr3"].should be_nil
        hash = JSON.parse(tst.to_json(:include_extras => [:attr3]))
        hash["attr3"].should_not be_nil
      end
      
      it "should ignore fields set under the except option" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2", :attr3 => "attr3"})
        hash = JSON.parse(tst.to_json(:except => [:attr1]))
        hash["attr1"].should be_nil
      end

    end
    
    context "XML" do
      
      it "should only be able to serialize itself with the root" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2"})
        hash = Hash.from_xml(tst.to_xml)
        hash["test_resource"].should_not be_nil
      end
      
      it "should properly serialize associations if they are included" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2", :has_many_objects => []})
        hash = Hash.from_xml(tst.to_xml(:include_associations => [:has_many_objects]))
        hash["test_resource"]["has_many_objects"].should eql([])
      end
    end
    
  end
  
  describe "Finding Data" do
    
    before(:all) do
      TestResource.reload_class_attributes
    end
    
    it "should be able to find all" do
      resources = TestResource.find(:all)
      resources.size.should eql(5)
      resources.each{|r| r.should be_a TestResource}
    end
    
    it "should be able to find first or last" do
      res = TestResource.first
      res.should be_a TestResource
      res.name.should_not be_blank
      res.age.should_not be_blank
      
      res = TestResource.last
      res.should be_a TestResource
      res.name.should_not be_blank
      res.age.should_not be_blank
    end
    
    it "should be able to find by id" do
      res = TestResource.find(2)
      res.should be_a TestResource
      res.id.to_i.should eql(2)
    end
    
  end
  
  describe "Saving Data" do
    
    before(:all) do
      TestResource.include_root_in_json = true
      TestResource.reload_class_attributes
    end
    
    context "Creating new records" do
      
      before(:all) do
        TestResource.has_many :has_many_objects
      end
    
      it "should be able to post new data via the create method" do
        tr = TestResource.create({:name => "Ethan", :age => 20})
        tr.id.should_not be_blank
      end
    
      it "should be able to post new data via the save method" do
        tr = TestResource.build({:name => "Ethan", :age => 20})
        tr.save.should be_true
        tr.id.should_not be_blank
      end
      
      context("Override create to return the json") do
        
        before(:all) do
          TestResource.send(:alias_method, :old_create, :create)
          TestResource.send(:alias_method, :old_save, :save)
          
          TestResource.send(:define_method, :create) do |*args|
            opts = args.extract_options!
            # When we create we should not include any blank attributes unless they are associations
            except = self.class.include_blank_attributes_on_create ? {} : self.attributes.select{|k,v| v.blank?}
            opts[:except] = opts[:except] ? opts[:except].concat(except.keys).uniq.symbolize_array : except.keys.symbolize_array
            opts[:include_associations] = opts[:include_associations] ? opts[:include_associations].concat(args) : []
            opts[:include_extras] ||= []
            encode(opts)
          end
          TestResource.send(:define_method, :save) do |*args|
            new? ? create(*args) : update(*args)
          end
        end
        
        after(:all) do
          TestResource.send(:alias_method, :create, :old_create)
          TestResource.send(:alias_method, :save, :old_save)
        end
      
        it "should be able to include associations when saving if they are specified" do
          tr = TestResource.build(:name => "Ethan", :age => 20)
          hash = JSON.parse(tr.save)
          hash['test_resource']['has_many_objects'].should be_nil
          hash = JSON.parse(tr.save(:include_associations => [:has_many_objects]))
          hash['test_resource']['has_many_objects'].should eql([])
        end
      
        it "should not include nil attributes when creating by default" do
          tr = TestResource.build(:name => "Ethan")
          hash = JSON.parse(tr.save)
          hash['test_resource']['age'].should be_nil
          hash['test_resource']['name'].should eql("Ethan")
        end
      
        it "should include nil attributes if they are passed in through the include_extras" do
          tr = TestResource.build(:name => "Ethan")
          hash = JSON.parse(tr.save(:include_extras => [:age]))
          hash['test_resource'].key?('age').should be_true
        end
      
        it "should include nil attributes when creating if include_nil_attributes_on_create is true" do
          TestResource.include_blank_attributes_on_create = true
          tr = TestResource.build(:name => "Ethan")
          hash = JSON.parse(tr.save)
          hash['test_resource'].key?('age').should be_true
          TestResource.include_blank_attributes_on_create = false
        end
      end
    end
    
    context "Updating old records" do
      before(:all) do
        TestResource.send(:alias_method, :old_update, :update)
        TestResource.send(:alias_method, :old_save, :save)
        
        TestResource.send(:define_method, :update) do |*args|
          opts = args.extract_options!
          # When we create we should not include any blank attributes
          except = self.class.attribute_names - self.changed.symbolize_array
          changed_associations = self.changed.symbolize_array.select{|item| self.association?(item)}
          opts[:except] = opts[:except] ? opts[:except].concat(except).uniq.symbolize_array : except.symbolize_array
          opts[:include_associations] = opts[:include_associations] ? opts[:include_associations].concat(args).concat(changed_associations).uniq : changed_associations.concat(args)
          opts[:include_extras] ||= []
          opts[:except] = [:id] if self.class.include_all_attributes_on_update
          encode(opts)
        end
        TestResource.send(:define_method, :save) do |*args|
          new? ? create(*args) : update(*args)
        end
      end
    
      after(:all) do
        TestResource.send(:alias_method, :update, :old_update)
        TestResource.send(:alias_method, :save, :old_save)
      end
      
      it "should be able to put updated data via the update method" do
        tr = TestResource.new(:id => 1, :name => "Ethan")
        tr.should_not be_new
        # Thus we know we are calling update
        tr.age = 6
        hash = JSON.parse(tr.update)
        hash['test_resource']['age'].should eql(6)
        
        hash = JSON.parse(tr.save)
        hash['test_resource']['age'].should eql(6)
      end
      
      it "should only include changed attributes when updating" do
        tr = TestResource.new(:id => 1, :name => "Ethan")
        tr.should_not be_new
        # Thus we know we are calling update
        tr.age = 6
        hash = JSON.parse(tr.save)
        hash['test_resource']['name'].should be_nil
      end
      
      it "should include changed associations without specification" do
        tr = TestResource.new(:id => 1, :name => "Ethan")
        tr.has_many_objects = [TestResource.new]
        hash = JSON.parse(tr.save)
        hash['test_resource']['has_many_objects'].should_not be_blank
      end
      
      it "should include unchanged associations if they are specified" do
        tr = TestResource.new(:id => 1, :name => "Ethan")
        hash = JSON.parse(tr.save(:has_many_objects))
        hash['test_resource']['has_many_objects'].should eql([])
      end
      
      it "should include all attributes if include_all_attributes_on_update is true" do
        TestResource.include_all_attributes_on_update = true
        tr = TestResource.new(:id => 1, :name => "Ethan")
        hash = JSON.parse(tr.save)
        hash['test_resource']['name'].should eql("Ethan")
        hash['test_resource'].key?('age').should be_true
        TestResource.include_all_attributes_on_update = false
      end
    
      it "should provide an update_attributes method to set attrs and save" do
        
        tr = TestResource.new(:id => 1, :name => "Ethan")
        hash = JSON.parse(tr.update_attributes(:name => "Dan"))
        hash['test_resource']['name'].should eql "Dan"
        
      end
      
      
    end
  
  end
  
  describe "Deleting data" do
    it "should be able to delete an id from the class method" do
      TestResource.delete(1).should be_true
    end
    
    it "should be able to destroy itself as an instance" do
      tr = TestResource.new(:id => 1, :name => "Ethan")
      tr.destroy.should be_true
    end
  end
  
  describe "Random methods" do
    
    it "should know if it is persisted" do
      tr = TestResource.new(:id => 1, :name => "Ethan")
      tr.persisted?.should be_true
      tr = TestResource.new(:name => "Ethan")
      tr.persisted?.should be_false
    end
    
  end
  
  describe "Inheritable Accessors" do
    
    it "should copy the default values down to any level of subclass" do
      
      class Child < TestResource
      end
      
      Child.site.should eql(TestResource.site)
      Child.site.should_not be_blank
    end
    
  end
  
end