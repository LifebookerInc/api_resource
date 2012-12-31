require 'spec_helper'

describe ApiResource::Typecast::DateTypecaster do

  let(:klass) { ApiResource::Typecast::DateTypecaster }

  context ".from_api" do

    it "should parse a date in iso format without Date._parse" do
      Date.expects(:_parse).never
      val = klass.from_api("2012-12-21")
      val.year.should eql(2012)
      val.month.should eql(12)
    end

    it "should parse a date in non iso format with Date._parse" do
      val = klass.from_api("2012/12/21")
      val.year.should eql(2012)
      val.month.should eql(12)
    end

    it "should return nil on a blank date or a year of 0" do
      klass.from_api("").should be_nil
      klass.from_api("0000-12-21").should be_nil
    end

    it "should just return if it's passed a Date" do
      new_date = Date.new
      date = Date.today
      klass.from_api(new_date).object_id.should eql(new_date.object_id)
      klass.from_api(date).object_id.should eql(date.object_id)
    end

    it "should return a valid date if passed a time" do
      new_time = Time.new
      time = Time.now
      val = klass.from_api(new_time)
      val.year.should eql(new_time.year)
      val.day.should eql(new_time.day)

      val = klass.from_api(time)
      val.year.should eql(time.year)
      val.day.should eql(time.day)
    end

    it "should not fail for any conceivable value" do
      [nil, "", 0, 1.0, 10, 0.0, "abc"].each do |val|
        klass.from_api(val).should be_nil
      end
    end

  end

  context ".to_api" do
    it "should just call to_s" do
      val = Time.now
      val.expects(:to_s).returns("hello world")
      klass.to_api(val).should eql("hello world")
    end
  end

end
