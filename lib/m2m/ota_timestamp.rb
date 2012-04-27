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

    def to_w
      [@id, @type, htonq(@value)].flatten.pack("CCQ")
    end

    def self.from_w(buffer)
      obj = buffer.unpack('CCQ')
      objId = obj[0]
      objType = obj[1]
      objValue = htonq(obj[2])

      raise OTAException.new('Invalid TIMESTAMP from wire') unless objType == OBJTYPE_TIMESTAMP

      new(objValue, objId)
    end

  end

end