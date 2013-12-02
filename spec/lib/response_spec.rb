require 'spec_helper'

module ApiResource

  describe Response do

    context '#initialize' do

      it 'handles a blank body' do
        raw_response = stub(headers: {}, body: nil)
        expect(Response.new(raw_response)).to be_blank
      end

    end

  end

end