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
  
  header_size = 			13;
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

  class OTA_Byte_Object
    def initialize(objId, objValue)
      @objType  = OBJTYPE_BYTE
      @objId    = objId
      @objValue = objValue
    end

    # to_wire
    def to_w
      [@objId, @objType, @objValue].pack('CCC')
    end
    
    def to_s
      "<object id='#{@objId}' type='byte' value='#{@objValue}'>"
    end
  end

  class OTA_Float_Object
    def initialize(objId, objValue)
      @objType  = OBJTYPE_FLOAT
      @objId    = objId
      @objValue = objValue
    end

    # to_wire
    def to_w
      [@objId, @objType, @objValue].pack('CCg')
    end
    
    def to_s
      "<object id='#{@objId}' type='float' value='#{@objValue}'>"
    end
  end

  class OTA_String_Object
    def initialize(objId, objValue)
      @objType  = OBJTYPE_STRING
      @objId    = objId
      @objValue = objValue
    end

    # to_wire
    def to_w
      [@objId, @objType, @objValue.length, @objValue].pack("CCnA*")
    end
    
    def to_s
      "<object id='#{@objId}' type='string' value='#{@objValue}'>"
    end
  end
  
  class OTA_Message
    
    attr_accessor  :messageType, :eventCode, :sequenceId,  :timestamp
    attr_reader    :majorVersion, :minorVersion
    attr_reader    :objects
    
    def initialize
      @messageType  = 0
      @majorVersion = MAJOR_VERSION
      @minorVersion = MINOR_VERSION
      @eventCode    = 0
      @sequenceId   = 0
      @timestamp    = 0
      @objects      = []
    end
    
    def header
      version = (majorVersion << 4) | minorVersion
      header = [messageType, version, eventCode, sequenceId, htonq(timestamp)]
      header.pack("CCCnQ")
    end
    
    def add_byte(objId, objValue)
      byteObj = OTA_Byte_Object.new(objId, objValue)
      @objects << byteObj
    end

    def add_float(objId, objValue)
      floatObj = OTA_Float_Object.new(objId, objValue)
      @objects  << floatObj
    end

    def add_string(objId, objValue)
      stringObj = OTA_String_Object.new(objId, objValue)
      @objects << stringObj
    end

    # to_w
    def to_w
      msg = header
      msg   += [@objects.length].pack("C")
      @objects.each do |object|
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
