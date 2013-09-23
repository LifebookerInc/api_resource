require 'spec_helper'

describe ApiResource::Formats::JsonFormat do


  context "#decode" do

    it "should not err on a blank response from an api" do

      blank_str = "      \n     "
      lambda{
        subject.decode(blank_str)
      }.should_not raise_error

    end

  end

end
