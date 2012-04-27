require_relative 'ota_object'

module M2M

  class OTATimestamp < OTAObject

    extend OTACommon

    def initialize(value,id = 0)
      case value
        when Hash
          super(value)
        when Time
          super(:id => id,:value => value.to_i * 1000)
        when Fixnum
          super(:id => id,:value => value.to_i)
        else
          raise OTAException.new("Invalid timestamp value type: #{value.class}")
      end
    end

    def self.expected_type
      OBJTYPE_TIMESTAMP
    end

    def self.unpack_value(buffer,format)
      buffer.unpack(format).collect{|result| htonq(result)}
    end

    def packable_value
      htonq(value)
    end

    def value_string
      %(#{Time.at(value / 1000).utc.strftime('%Y-%m-%dT%H:%M:%S')}.%03d) % (value % 1000)
    end

  end

end