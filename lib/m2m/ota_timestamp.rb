require_relative 'ota_object'

module M2M

  class OTATimestamp < OTAObject

    extend OTACommon

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_TIMESTAMP
    end

    def to_w
      [@objId, @objType, htonq(@objValue)].flatten.pack("CCQ")
    end

    def self.from_w(buf)
      obj = buf.unpack('CCQ')
      objId = obj[0]
      objType = obj[1]
      objValue = htonq(obj[2])

      raise OTAException.new('Invalid object from wire') if objType != OBJTYPE_TIMESTAMP

      OTATimestamp.new(objValue, objId)
    end

    def to_s
      "<object id'#{@objId}' type='array[int]' value='#{@objValue}'>"
    end

  end

end