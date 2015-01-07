require 'active_support/time'

module ApiResource

  module Typecast

    ISO_DATETIME = /\A(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)(\.\d+)?\z/

    module TimeTypecaster

      def self.from_api(value)
        return value if value.is_a?(Time)
        value = value.to_s
        return nil if value.empty?

        if value =~ ApiResource::Typecast::ISO_DATETIME
          micro = ($7.to_f * 1_000_000).to_i
          return self.new_time(false, $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, micro)
        end

        time_info = Date._parse(value)
        time_info[:micro] = ((time_info[:sec_fraction].to_f % 1) * 1_000_000).to_i

        if time_info[:zone].present?
          new_time(true, *time_info.values_at(:year, :mon, :mday, :hour, :min, :sec, :zone))
        else
          new_time(false, *time_info.values_at(:year, :mon, :mday, :hour, :min, :sec, :micro))
        end

      end

      def self.to_api(value)
        return value.to_s
      end

      protected

      def self.new_time(use_zone, *args)
        year = args.first
        return nil if year.nil? || year == 0
        if use_zone
          Time.new(*args).utc rescue nil
        else
          Time.utc(*args) rescue nil
        end
      end

    end

  end

end
