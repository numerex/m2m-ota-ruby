require_relative 'ota_object'

module M2M

  class OTAIntArray < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_ARRAY_INT
    end

    def to_w
      [@objId, @objType, @objValue.length * 4, 4, @objValue].flatten.pack('CCnCN*')
    end

    def self.from_w(buf)

      obj       = buf.unpack('CCnC')
      objId     = obj[0]
      objType   = obj[1]
      objLen    = obj[2]
      objEleLen = obj[3]
      objValue  = buf[5, objLen].unpack('N*')

      raise OTAException.new('Invalid object from wire') if objType != OBJTYPE_ARRAY_INT

      OTAIntArray.new(objValue, objId)
    end

    def to_s
      "<object id'#{@objId}' type='array[int]' value='#{@objValue}'>"
    end

  end

end