module M2M_OTA

  MOBILE_ORIGINATED_EVENT = 0xAA
  MOBILE_ORIGINATED_ACK   = 0xBB
  MOBILE_TERMINATED_EVENT = 0xCC
  MOBILE_TERMINATED_ACK   = 0xDD
  
  OBJTYPE_BYTE        = 0
  OBJTYPE_INT         = 1
  OBJTYPE_STRING      = 2
  OBJTYPE_FLOAT       = 3
  OBJTYPE_TIMESTAMP   = 4
  OBJTYPE_ARRAY_BYTE  = 5
  OBJTYPE_ARRAY_INT   = 6
  OBJTYPE_ARRAY_FLOAT = 7
  
  SIZE_OF_FLOAT       = 4
  SIZE_OF_TIMESTAMP   = 8
  
  MAJOR_VERSION       = 1
  MINOR_VERSION       = 0
  
  MESSAGE_TYPE_POS     = 0
  PROTOCOL_VERSION_POS = 1
  EVENT_CODE_POS       = 2
  SEQ_ID_POS           = 3
  TIMESTAMP_POS        = 5
  
  MAX_PACKET_SIZE      = 1024

  BigEndian = [1].pack("s") == [1].pack("n")

  def htonq val
    BigEndian ? val : ([val].pack("Q").reverse.unpack("Q").first)
  end

  class OTA_Exception < Exception
  end
  
  class OTA_Object
    attr_accessor :objId, :objValue
    def initialize(objValue, objId = 0)
      @objId    = objId
      @objValue = objValue
    end
  end
  
  class OTA_Byte < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_BYTE
    end
    
    # to_wire
    def to_w
      [@objId, @objType, @objValue].pack('CCC')
    end
    
    def to_s
      "<object id='#{@objId}' type='byte' value='#{@objValue}'>"
    end
  end

  class OTA_Int < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_INT
    end

    # Ruby implementation uses 4 bytes for all integers
    def to_w
      [@objId, @objType, 4, @objValue].pack('CCCN')
    end

    def to_s
      "<object id='#{@objId}' type='byte' value='#{@objValue}'>"
    end
  end

  class OTA_Float < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_FLOAT
    end
    
    # to_wire
    def to_w
      [@objId, @objType, @objValue].pack('CCg')
    end
    
    def to_s
      "<object id='#{@objId}' type='float' value='#{@objValue}'>"
    end
  end
  
  class OTA_String < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_STRING
    end
    
    # to_wire
    def to_w
      [@objId, @objType, @objValue.length, @objValue].pack("CCnA*")
    end
    
    def to_s
      "<object id='#{@objId}' type='string' value='#{@objValue}'>"
    end
  end

  class OTA_Float_Array < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType  = OBJTYPE_ARRAY_FLOAT
    end

    def to_w
      [@objId, @objType, @objValue.length * 4, 4, @objValue].flatten.pack("CCnCg*")
    end

    def to_s
      "<object id'#{@objId}' type='array[float]' value='#{@objValue}'>"
    end
  end

  class OTA_Byte_Array < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_ARRAY_BYTE
    end

    def to_w
      [@objId, @objType, @objValue.length, @objValue].flatten.pack("CCnC*")
    end

    def to_s
      "<object id'#{@objId}' type='array[byte]' value='#{@objValue}'>"
    end
  end

  class OTA_Int_Array < OTA_Object
    def initialize(objValue, objId = 0)
      super(objValue, objId)
      @objType = OBJTYPE_ARRAY_INT
    end

    def to_w
      [@objId, @objType, @objValue.length * 4, 4, @objValue].flatten.pack("CCnN*")
    end

    def to_s
      "<object id'#{@objId}' type='array[int]' value='#{@objValue}'>"
    end
  end
  
  class OTA_Message
    
    attr_accessor  :messageType, :eventCode, :sequenceId,  :timestamp
    attr_accessor  :autoObjectId
    attr_reader    :majorVersion, :minorVersion
    attr_reader    :objects
    
    def initialize(p={})
      @messageType  = p[:messageType] || 0
      @majorVersion = MAJOR_VERSION
      @minorVersion = MINOR_VERSION
      @eventCode    = p[:eventCode]   || 0
      @sequenceId   = p[:sequenceId]  || 0
      @timestamp    = p[:timestamp]   || Time.now.to_i * 1000
      @objects      = []

      @autoObjectId = false
    end
    
    def header
      version = (majorVersion << 4) | minorVersion
      header = [messageType, version, eventCode, sequenceId, htonq(timestamp)]
      header.pack("CCCnQ")
    end

    def <<(obj)
      raise OTA_Exception.new("Invalid object added to message") if not obj.is_a? OTA_Object
      @objects << obj
    end
    
    # to_w
    def to_w
      msg = header
      msg   += [@objects.length].pack("C")

      if @autoObjectId then
        autoObjectId = 1
        autoSet = lambda {|o|
          o.objId       = autoObjectId
          autoObjectId += 1
        }
      end
      @objects.each do |object|
        autoSet.call(object) if autoSet
        msg += object.to_w
      end
      msg
    end

    def to_s
      str  = "<ota>\n"
      str += " <raw>\n"
      str += " </raw>\n"
      str += " <header>\n"
      str += "  <type>M</type>\n"
      str += "  <version>\n"
      str += "   <major>#{@majorVersion}</major>\n"
      str += "   <minor>#{@minorVersion}</minor>\n"
      str += "  </version>\n"
      str += "  <eventcode>#{@eventCode}</eventcode>\n"
      str += "  <sequenceid>#{@sequenceId}</sequenceid>\n"
      str += "  <timestamp>#{@timestamp}</timestamp>\n"
      str += " </header>\n"
      str += " <objects>\n"
      @objects.each do |object|
        str += "   #{object}\n"
      end
      str += " </objects>\n"
      str += " <crc></crc>\n"
      str += "</ota>\n"
      str
    end

  end
end
