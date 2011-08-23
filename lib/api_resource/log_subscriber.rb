module ApiResource
  class LogSubscriber < ActiveSupport::LogSubscriber
    def request(event)
      result = event[:payload]
      info "#{event.payload[:method].to_s.upcase} #{even.payload[:request_uri]}"
      info "--> %d %s %d (%.1fms)" % [result.code, result.message, result.body.to_s.length, event.duration]
    end
    
    def logger
      Rails.logger
    end
  end
end

ApiResource::LogSubscriber.attach_to :api_resource