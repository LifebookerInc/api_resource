require 'spec_helper'

describe ApiResource::Typecast::StringTypecaster do

  let(:klass) { ApiResource::Typecast::StringTypecaster }

  context ".from_api" do 

    it "should work on any conceivable value" do
      klass.from_api(BasicObject).should eql("BasicObject")
      klass.from_api(true).should eql("true")
      klass.from_api(false).should eql("false")
      klass.from_api(nil).should eql("")
      klass.from_api("").should eql("")
      klass.from_api("abc").should eql("abc")
      klass.from_api(1).should eql("1")
      klass.from_api(1.0).should eql("1.0")
    end
  end

  context ".to_api" do
    it "should return itself" do
      val = "hello"
      klass.to_api(val).object_id.should eql(val.object_id)
    end
  end

end
