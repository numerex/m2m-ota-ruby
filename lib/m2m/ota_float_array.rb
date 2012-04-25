require_relative 'ota_object'

module M2M

  class OTAFloatArray < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_ARRAY_FLOAT
    end

    def to_w
      [@objId, @objType, @objValue.length * 4, 4, @objValue].flatten.pack('CCnCg*')
    end

    def self.from_w(buf)
      obj       = buf.unpack('CCnC')
      objId     = obj[0]
      objType   = obj[1]
      objLen    = obj[2]
      objEleLen = obj[3]
      objValue  = buf[5, objLen].unpack('g*')

      raise OTAException.new('Invalid FLOAT ARRAY from wire') if objType != OBJTYPE_ARRAY_FLOAT

      OTAFloatArray.new(objValue, objId)
    end

    def to_s
      "<object id'#{@objId}' type='array[float]' value='#{@objValue}'>"
    end

  end

end