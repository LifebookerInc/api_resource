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
        TestResource.known_attributes :attr1, :attr2
      end
    
      it "should set attributes for the data loaded from a hash" do
        tst = TestResource.new({:attr1 => "attr1", :attr2 => "attr2"})
        tst.attr1?.should be_true
        tst.attr1.should eql("attr1")
        tst.attr1 = "test"
        tst.attr1.should eql("test")
      end
    
      it "should create attribute methods on this instance for unknown attributes trying to be loaded" do
        tst = TestResource.new({:attr1 => "attr1", :attr3 => "attr3"})
        tst.attr3?.should be_true
        tst.attr3.should eql("attr3")
        tst.attr3 = "test"
        tst.attr3.should eql("test")
        tst.attribute?(:attr3).should be_false
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
      TestResource.known_attributes :attr1, :attr2
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
    
      it "should be able to post new data via the create method" do
        tr = TestResource.create({:name => "Ethan", :age => 20})
        tr.id.should_not be_blank
      end
    
      it "should be able to post new data via the save method" do
        tr = TestResource.build({:name => "Ethan", :age => 20})
        tr.save.should be_true
        tr.id.should_not be_blank
      end
      
      it "should be able to post data with a file in it"
      
      it "should be able to include associations when saving if they are specified"
      
      it "should not include nil attributes when creating by default"
      
      it "should include nil attributes when creating if include_nil_attributes_on_create is true"
    end
    
    context "Updating old records" do
      
      it "should be able to put updated data via the update method"
      
      it "should be able to put updated data via the save method"
      
      it "should be able to put data with a file in it"
      
      it "should only include changed attributes when updating"
      
      it "should include changed associations without specification"
      
      it "should include unchanged associations if they are specified"
      
    end
  
  end
  
  describe "Deleting data" do
    it "should be able to delete an id from the class method"
    
    it "should be able to destroy itself as an instance"
  end
  
  describe "Random methods" do
    
    it "should be able to save with save! or raise an error if it fails"
    
    it "should be able to duplicate itself with dup"
    
    it "should know if it is persisted"
    
  end
  
end