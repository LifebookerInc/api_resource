require 'spec_helper'

describe ApiResource::Typecast::BooleanTypecaster do

  let(:klass) { ApiResource::Typecast::BooleanTypecaster }

  context ".from_api" do

    it "should typecast any value in the true array to true" do
      ApiResource::Typecast::TRUE_VALUES.each do |value|
        klass.from_api(value).should be_instance_of(TrueClass)
      end
    end

    it "should return false for any other conceivable input" do
      [Date.new, Time.new, Date.today, Time.now, nil, false, Float, 2.0, 2, "", "bad value"].each do |val|
        klass.from_api(val).should be_instance_of(FalseClass)
      end
    end

  end

  context ".to_api" do

    it "should return whatever value is passed in" do
      [nil, true, 1, 0.5, Time.now].each do |val|
        klass.to_api(val).should eql(val)
      end
    end

  end

end
