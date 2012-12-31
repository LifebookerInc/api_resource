require 'spec_helper'

describe ApiResource::Typecast::IntegerTypecaster do

  let(:klass) { ApiResource::Typecast::IntegerTypecaster}

  context ".from_api" do

    it "should typecast integers, floats, strings, dates, and times reasonably" do
      klass.from_api(1).should eql(1)
      klass.from_api(1.0).should eql(1)
      klass.from_api(1.67).should eql(1)
      klass.from_api("1.0").should eql(1)
      klass.from_api("1").should eql(1)
      klass.from_api("0.123").should eql(0)
      klass.from_api(false).should eql(0)
      klass.from_api(true).should eql(1)
      klass.from_api(Date.today).should eql(Date.today.year)

      tme = Time.now
      klass.from_api(tme).should eql(tme.to_i)
    end

    it "should be able to typecast any value you can think of" do
      klass.from_api(nil).should eql(0)
      klass.from_api("").should eql(0)
      klass.from_api(BasicObject).should eql(0)
      klass.from_api("abc").should eql(0)
    end

  end

  context ".to_api" do
    it "should return itself" do
      val = 1
      klass.to_api(val).object_id.should eql(val.object_id)
    end
  end

end
