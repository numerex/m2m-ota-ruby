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

  def timestamp
    Time.now.to_i * 1000
  end

  def crc(data)
    _m = 0
    _p = 0
    _r = data[0].unpack('C')[0]

    indexes = (1..data.length-1)
    indexes.each do |i|
      _d = data[i].unpack('C')[0]
      _r = (_r << 8) | _d
      _p = 0x0107 << 7
      _m = 0x8000
      while _m != 0x0080 do 
        if (_r & _m) != 0 then
          _r ^= _p
        end
        _p = (_p & 0x0000ffff) >> 1
        _m = (_m & 0x0000ffff) >> 1
      end
    end
    _r
  end

  class OTA_Object
    attr_accessor :objId, :objValue
    def initialize(objValue, objId = 0)
      @objId    = objId
      @objValue = objValue
    end
    def length 
      self.to_w.length
    end
  end
  
  class OTA_Byte < OTA_Object
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
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_BYTE
      OTA_Byte.new(objValue, objId)
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
        objValue = buf[3..4].unpack("n")[0]
        when 4
        objValue = buf[3..7].unpack("N")[0]
        else
        raise OTA_Exception.new("Integer object size from wire invalid") if objType != OBJTYPE_INT
      end
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_INT
      OTA_Int.new(objValue, objId)
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

    def self.from_w(buf)
      obj = buf.unpack('CCg')
      objId    = obj[0]
      objType  = obj[1]
      objValue = obj[2]
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_FLOAT
      OTA_Float.new(objValue, objId)
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

    # from_w
    def self.from_w(buf)
      obj     = buf.unpack('CCn')
      objId   = obj[0]
      objType = obj[1]
      strLen  = obj[2]
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_STRING

      objValue = buf[4, strLen].unpack("A*")[0]
      OTA_String.new(objValue, objId)
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

    def self.from_w(buf)
      obj       = buf.unpack('CCnC')
      objId     = obj[0]
      objType   = obj[1]
      objLen    = obj[2]
      objEleLen = obj[3]
      objValue  = buf[5, objLen].unpack("g*")
      
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_ARRAY_FLOAT
      
      OTA_Float_Array.new(objValue, objId)
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

    def self.from_w(buf)
      obj       = buf.unpack('CCn')
      objId     = obj[0]
      objType   = obj[1]
      objLen    = obj[2]
      objValue  = buf[4, objLen].unpack("C*")
      
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_ARRAY_BYTE
      
      OTA_Byte_Array.new(objValue, objId)
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
      [@objId, @objType, @objValue.length * 4, 4, @objValue].flatten.pack("CCnCN*")
    end

    def self.from_w(buf)

      obj       = buf.unpack('CCnC')
      objId     = obj[0]
      objType   = obj[1]
      objLen    = obj[2]
      objEleLen = obj[3]
      objValue  = buf[5, objLen].unpack("N*")
      
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_ARRAY_INT
      
      OTA_Int_Array.new(objValue, objId)
    end

    def to_s
      "<object id'#{@objId}' type='array[int]' value='#{@objValue}'>"
    end
  end

  class OTA_Timestamp < OTA_Object
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
      
      raise OTA_Exception.new("Invalid object from wire") if objType != OBJTYPE_TIMESTAMP
      
      OTA_Timestamp.new(objValue, objId)
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

      if p[:data] then
        from_w p[:data]
      else
        @messageType  = p[:messageType] || 0
        @majorVersion = MAJOR_VERSION
        @minorVersion = MINOR_VERSION
        @eventCode    = p[:eventCode]   || 0
        @sequenceId   = p[:sequenceId]  || 0
        @timestamp    = p[:timestamp]   || Time.now.to_i * 1000
        @objects      = []
        
        @autoObjectId = false
      end
    end
    
    # @return [String] Binary string header of the message
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
    def to_w(calc_crc = true)
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
      # Checksum byte
      if calc_crc
        msg += [crc(msg)].pack('C')
      end
      msg
    end

    def to_hex
      str  = ""
      wire = self.to_w
      wire.each_byte do |w|
        str += sprintf("%x", w)
      end
      str
    end

    # 
    # @param [String] Binary string containing a received OTA message
    def from_w(msg)
      header = msg.unpack("CCCnQ")
      @messageType  = header[0]
      @majorVersion = header[1] >> 4
      @minorVersion = header[1] & 0x0F
      @eventCode    = header[2]
      @sequenceId   = header[3]
      @timestamp    = htonq(header[4])
      @objects      = []
      @autoObjectId = 0


      msgLen = msg.length
      msgPtr = 14 # First index of objects

      remainingObjBuf = msg[msgPtr..msgLen]
      while msgPtr != msgLen - 1
        objHeader = remainingObjBuf.unpack("CC")
        objId     = objHeader[0]
        objType   = objHeader[1]

        case objType
        when OBJTYPE_BYTE
          obj = OTA_Byte.from_w(remainingObjBuf)
        when OBJTYPE_INT
          obj = OTA_Int.from_w(remainingObjBuf)
        when OBJTYPE_FLOAT
          obj = OTA_Float.from_w(remainingObjBuf)
        when OBJTYPE_STRING
          obj = OTA_String.from_w(remainingObjBuf)
        when OBJTYPE_ARRAY_FLOAT
          obj = OTA_Float_Array.from_w(remainingObjBuf)
        when OBJTYPE_ARRAY_BYTE
          obj = OTA_Byte_Array.from_w(remainingObjBuf)
        when OBJTYPE_ARRAY_INT
          obj = OTA_Int_Array.from_w(remainingObjBuf)
        when OBJTYPE_TIMESTAMP
          obj = OTA_Timestamp.from_w(remainingObjBuf)
        else
          raise OTA_Exception.new("Invalid object type in message at byte %d" % msgPtr)
        end
        
        @objects << obj
        
        msgPtr += obj.length
        remainingObjBuf = msg[msgPtr..msgLen]

      end
      
      msgCrc = msg[msgPtr].unpack('C')[0]
      objCrc  = crc(self.to_w(calc_crc = false))
      
      raise OTA_Exception.new("CRC error") if msgCrc != objCrc

    end

    def to_s
      str  = "<ota>\n"
      str += " <raw>"
      str += self.to_hex
      str += "</raw>\n"
      str += " <header>\n"
      str += "  <type>#{@messageType}</type>\n"
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
      str += "</ota>\n"
      str
    end

  end
end
