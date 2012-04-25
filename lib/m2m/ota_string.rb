require_relative 'ota_object'

module M2M

  class OTAString < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_STRING
    end

    # to_wire
    def to_w
      [@objId, @objType, @objValue.length, @objValue].pack('CCnA*')
    end

    # from_w
    def self.from_w(buf)
      obj     = buf.unpack('CCn')
      objId   = obj[0]
      objType = obj[1]
      strLen  = obj[2]
      raise OTAException.new('Invalid STRING from wire') if objType != OBJTYPE_STRING

      objValue = buf[4, strLen].unpack('A*')[0]
      OTAString.new(objValue, objId)
    end

    def to_s
      "<object id='#{@objId}' type='string' value='#{@objValue}'>"
    end

  end

end