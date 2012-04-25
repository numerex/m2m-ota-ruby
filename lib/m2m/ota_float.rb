require_relative 'ota_object'

module M2M

  class OTAFloat < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_FLOAT
    end

    # to_wire
    def to_w
      [@objId, @objType, @objValue].pack('CCg')
    end

    def self.from_w(buf)
      obj = buf.unpack('CCg')
      objId    = obj[0]
      objType  = obj[1]
      objValue = obj[2]
      raise OTAException.new('Invalid FLOAT from wire') if objType != OBJTYPE_FLOAT
      OTAFloat.new(objValue, objId)
    end

    def to_s
      "<object id='#{@objId}' type='float' value='#{@objValue}'>"
    end

  end

end