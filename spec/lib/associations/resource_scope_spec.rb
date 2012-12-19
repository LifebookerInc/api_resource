require 'spec_helper'

describe ApiResource::Associations::ResourceScope do
  

  context "#load" do

    it "should perform the correct query" do

      TestResource.expects(:all)
        .with(:params => {
          "birthday" => {
            "date" => "2012-01-01"
          }
        })
        .returns([])

      TestResource.birthday("2012-01-01").first

    end

  end

end