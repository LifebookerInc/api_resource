module ApiResource

  module Typecast

    ISO_DATE = /\A(\d{4})-(\d\d)-(\d\d)\z/

    module DateTypecaster

      def self.from_api(value)
        return value if value.is_a?(Date)

        value = value.to_s
        if value =~ ApiResource::Typecast::ISO_DATE
          return self.new_date($1.to_i, $2.to_i, $3.to_i)
        end

        self.new_date(*::Date._parse(value, false).values_at(:year, :mon, :mday))
      end

      def self.to_api(value)
        return value.to_s
      end

      protected

      def self.new_date(year, month, day)
        return nil unless year && year != 0
        return Date.new(year, month, day) rescue nil
      end

    end

  end

end
