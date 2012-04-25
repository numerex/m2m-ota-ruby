require_relative 'ota_object'

module M2M

  class OTAInt < OTAObject

    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_INT
    end

    # Ruby implementation uses 4 bytes for all integers
    def to_w
      [@objId, @objType, 4, @objValue].pack('CCCN')
    end

    # from_w
    def self.from_w(buf)
      obj = buf.unpack('CCC')
      objId     = obj[0]
      objType   = obj[1]
      objLength = obj[2]
      case objLength
        when 1
          objValue = buf[3].unpack('C')[0]
        when 2
          objValue = buf[3..4].unpack('n')[0]
        when 4
          objValue = buf[3..7].unpack('N')[0]
        else
          raise OTAException.new('Integer object size from wire invalid') if objType != OBJTYPE_INT
      end
      raise OTAException.new('Invalid INT from wire') if objType != OBJTYPE_INT
      OTAInt.new(objValue, objId)
    end

    def to_s
      "<object id='#{@objId}' type='byte' value='#{@objValue}'>"
    end

  end

end