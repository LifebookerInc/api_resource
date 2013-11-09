require 'spec_helper'

module ApiResource

  describe Serializer do

    before(:each) do
      TestResource.reload_resource_definition
      TestResource.has_many :has_many_objects
      TestResource.define_attributes :attr1, :attr2
      TestResource.include_root_in_json = false
    end

    after(:all) do
      TestResource.include_root_in_json = true
    end

    subject {
      Serializer.new(instance)
    }

    let(:instance){
      TestResource.new({
        attr1: "attr1",
        attr2: "attr2",
        has_many_objects: []
      })
    }

    context "#to_hash" do

      it 'includes attributes' do

        subject.to_hash["attr1"].should_not be_nil

      end

      it "should not include associations by default if
        they have not changed" do

        subject.to_hash["has_many_objects"].should be_nil
      end

      it "should include associations passed given in the include_associations array" do

        subject = Serializer.new(
          instance,
          include_associations: [:has_many_objects]
        )

        subject.to_hash["has_many_objects"].should_not be_nil
      end

      it "should include associations by default if they have changed" do
        instance.has_many_objects = [{name: "test"}]
        hash = subject.to_hash
        hash["has_many_objects"].should_not be_nil
      end

      it "should not include unknown attributes unless they
        are passed in via the include_extras array" do

        TestResource.class_eval do
          define_attributes :attr3, access_level: :protected
        end

        instance = TestResource.instantiate_record({
          attr1: "attr1",
          attr2: "attr2",
          attr3: "attr3"
        })

        subject = Serializer.new(instance)
        subject.to_hash["attr3"].should be_nil

        subject = Serializer.new(instance, include_extras: [:attr3])
        subject.to_hash["attr3"].should_not be_nil
      end

      it "should ignore fields set under the except option" do
        tst = TestResource.new({
          attr1: "attr1",
          attr2: "attr2"
        })
        hash = JSON.parse(tst.to_json(except: [:attr1]))
        hash["attr1"].should be_nil
        hash["attr2"].should be_present
      end

      context "Nested Objects" do

        before(:all) do
          TestResource.has_many(:has_many_objects)
        end

        after(:all) do
          TestResource.reload_resource_definition
        end

        it "should include the id of nested objects in the serialization" do
          instance.has_many_objects = [
            {name: "123", id: "1"}
          ]
          subject = Serializer.new(
            instance,
            include_associations: [:has_many_objects]
          )
          subject.to_hash["has_many_objects"].first["id"].should_not be_nil
        end

        it "should exclude include the id of new nested objects in the
           serialization" do
          instance.has_many_objects = [
            {name: "123"}
          ]
          subject = Serializer.new(
            instance,
            include_associations: [:has_many_objects]
          )
          object_hash = subject.to_hash["has_many_objects"].first
          object_hash.keys.should_not include "id"
        end

      end

      context 'Foreign keys' do

        context 'Prefixed' do

          before(:all) do
            TestResource.prefix =
              "/belongs_to_objects/:belongs_to_object_id/"
          end

          after(:all) do
            TestResource.prefix = "/"
          end

          it 'excludes the foreign key when it is nested in the prefix' do
            instance.belongs_to_object_id = 123
            subject.to_hash["belongs_to_object_id"].should be_blank
          end

        end

        it "should include the foreign_key_id when saving" do
          instance.stubs(:id => 123)
          instance.has_many_object_ids = [4]
          subject.to_hash[:has_many_object_ids].should eql([4])
        end

      end

    end
  end
end