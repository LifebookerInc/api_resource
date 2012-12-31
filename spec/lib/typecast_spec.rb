require 'spec_helper'

describe ApiResource::Typecast do

  let(:klass) { ApiResource::Base }

  context ".register_typecaster" do

    it "should be able to define a typecaster given a name and a module/class" do
      caster = Module.new do
        def self.from_api(value)
          return "hello"
        end
        def self.to_api(value)
        end
      end
      klass.register_typecaster(:String1, caster)
      klass.typecasters[:string1].from_api(1).should eql("hello")
    end

    it "should be able to define a typecaster given a block" do
      klass.register_typecaster(:String2) do
        def self.from_api(value)
          return "hello"
        end
        def self.to_api(value)
        end
      end

      klass.typecasters[:string2].from_api(1).should eql("hello")
    end

    it "should raise an error if given both a class and a block" do
      caster = Module.new do
        def self.from_api(value)
          return "hello"
        end
        def self.to_api(value)
        end
      end

      lambda {
        klass.register_typecaster(:String3, caster) do
          def self.from_api(value)
            return "hello"
          end
          def self.to_api(value)
          end
        end
        }.should raise_error ArgumentError, "Cannot declare a typecaster with a class and a block"
    end

    it "should raise an error if given neither a class nor a block" do
      lambda {
        klass.register_typecaster(:String4)
      }.should raise_error ArgumentError, "Must specify a typecaster with either a class or a block"
    end

    it "should raise an error if the typecaster already exists" do
      klass.register_typecaster(:String5) do
        def self.from_api(value)
          return "hello"
        end
        def self.to_api(value)
        end
      end
      lambda {
        klass.register_typecaster(:String5) do
          def self.from_api(value)
            return "goodbye"
          end
          def self.to_api(value)
          end
        end
      }.should raise_error ArgumentError, "Typecaster String5 already exists"
    end

    it "should raise an error if the klass does not respond_to? from_api" do
      lambda {
        klass.register_typecaster(:String6) do

        end
      }.should raise_error ArgumentError, "Typecaster must respond to from_api and to_api"
    end
  end

  context "redefine_typecaster!" do
    it "should be able to reregister a typecaster" do
      klass.register_typecaster(:String7) do
        def self.from_api(value)
          return "hello"
        end
        def self.to_api(value)
        end
      end
      klass.typecasters[:string7].from_api(1).should eql("hello")
      klass.redefine_typecaster!(:String7) do
        def self.from_api(value)
          return "goodbye"
        end
        def self.to_api(value)
        end
      end

      klass.typecasters[:string7].from_api(1).should eql("goodbye")
    end

    it "should redefine a typecaster only for subclasses of the class called on" do
      sib1 = Class.new(ApiResource::Base)
      sib2 = Class.new(ApiResource::Base)
      child = Class.new(sib2)
      # overriding a typecaster in sib2 should affect sib2 and child but not sib1
      sib2.redefine_typecaster!(:string) do
        def self.from_api(value)
          return "hello"
        end

        def self.to_api(value)
          return value
        end
      end

      sib1.typecasters[:string].from_api(1).should eql("1")
      ApiResource::Base.typecasters[:string].from_api(2).should eql("2")
      sib2.typecasters[:string].from_api(1).should eql("hello")
      child.typecasters[:string].from_api(1).should eql("hello")
    end

    it "should redefine a typecaster for all subclasses when called on ApiResource::Base" do
      grandparent = Class.new(ApiResource::Base)
      parent = Class.new(grandparent)
      child = Class.new(parent)

      grandparent.redefine_typecaster!(:string) do
        def self.from_api(value)
          return "goodbye"
        end

        def self.to_api(value)
          return value
        end
      end

      grandparent.typecasters[:string].from_api(2).should eql("goodbye")
      parent.typecasters[:string].from_api(2).should eql("goodbye")
      child.typecasters[:string].from_api(2).should eql("goodbye")
    end

    it "should be able to restore default typecasters" do
      ApiResource::Base.redefine_typecaster!(:string) do
        def self.from_api(value)
          return "goodbye"
        end

        def self.to_api(value)
          return value
        end
      end
      ApiResource::Base.typecasters[:string].from_api(2).should eql("goodbye")
      ApiResource::Base.redefine_typecaster!(:string, ApiResource::Base.default_typecasters[:string])
      ApiResource::Base.typecasters[:string].from_api(2).should eql("2")
    end
  end

  context ".typecasters" do
    it "should have default typecasters" do
      vals = [:boolean, :bool, :date, :decimal, :float, :integer,
       :int, :string, :time, :datetime, :array]
      vals.each do |val|
        klass.typecasters.keys.should include val
      end
    end
  end
end
