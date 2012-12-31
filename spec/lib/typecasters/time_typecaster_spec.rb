require 'spec_helper'

describe ApiResource::Typecast::TimeTypecaster do

  let(:klass) { ApiResource::Typecast::TimeTypecaster }

  context ".from_api" do


    it "should parse a time in ISO format in UTC" do
      val = klass.from_api("2012-12-21 04:44:44")
      val.year.should eql(2012)
      val.day.should eql(21)
      val.min.should eql(44)
      val.zone.to_s.should eql("UTC")
    end

    it "should parse a date in ISO format into a time" do
      val = klass.from_api("2012-12-21")
      val.year.should eql(2012)
      val.min.should eql(0)
      val.zone.to_s.should eql("UTC")
    end

    it "should parse a time not in ISO format" do
      val = klass.from_api("28/08/2012 04:55:56")
      val.year.should eql(2012)
      val.month.should eql(8)
      val.day.should eql(28)
    end

    it "should parse a date not in ISO format" do
      val = klass.from_api("2012/08/09")
      val.year.should eql(2012)
      val.month.should eql(8)
      val.min.should eql(0)
    end

    it "should return the same Time object if passed a time" do
      time = Time.now
      klass.from_api(time).object_id.should eql(time.object_id)
    end

    it "should return nil for a blank year" do
      klass.from_api("0000/02/08 08:55:56").should be_nil
    end

    it "should return nil for nonsense input" do
      lambda{
        [false, 1, nil, 0.0, [], {}].each do |bad|
          klass.from_api(bad)
        end
      }.should_not raise_error
    end

  end

  context ".to_api" do
    it "should return the time as a string" do
      val = Time.now
      klass.to_api(val).should eql(val.to_s)
    end
  end

end
