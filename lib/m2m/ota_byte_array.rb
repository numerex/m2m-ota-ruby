require_relative 'ota_object'

module M2M

  class OTAByteArray < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_ARRAY_BYTE
    end

    def to_w
      [@objId, @objType, @objValue.length, @objValue].flatten.pack('CCnC*')
    end

    def self.from_w(buf)
      obj       = buf.unpack('CCn')
      objId     = obj[0]
      objType   = obj[1]
      objLen    = obj[2]
      objValue  = buf[4, objLen].unpack('C*')

      raise OTAException.new('Invalid object from wire') if objType != OBJTYPE_ARRAY_BYTE

      OTAByteArray.new(objValue, objId)
    end

    def to_s
      "<object id'#{@objId}' type='array[byte]' value='#{@objValue}'>"
    end

  end

end