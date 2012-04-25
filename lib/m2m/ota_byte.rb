require_relative 'ota_object'

module M2M

  class OTAByte < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_BYTE
    end

    # to_w
    def to_w
      [@objId, @objType, @objValue].pack('CCC')
    end

    # from_w
    def self.from_w(buf)
      obj = buf.unpack('CCC')
      objId    = obj[0]
      objType  = obj[1]
      objValue = obj[2]
      raise OTAException.new('Invalid BYTE from wire') if objType != OBJTYPE_BYTE
      OTAByte.new(objValue, objId)
    end

    def to_s
      "<object id='#{@objId}' type='byte' value='#{@objValue}'>"
    end
  end

end