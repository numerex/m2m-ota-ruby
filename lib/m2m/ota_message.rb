module M2M

  class OTAMessage

    include OTACommon

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
      header.pack('CCCnQ')
    end

    def <<(obj)
      raise OTAException.new('Invalid object added to message') if not obj.is_a? OTAObject
      @objects << obj
    end

    # to_w
    def to_w(calc_crc = true)
      msg = header
      msg   += [@objects.length].pack('C')

      if @autoObjectId then
        autoObjectId = 1
        autoSet = lambda {|o|
          o.id       = autoObjectId
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
        str += sprintf('%x', w)
      end
      str
    end

    #
    # @param [String] Binary string containing a received OTA message
    def from_w(msg)
      header = msg.unpack('CCCnQ')
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
        objHeader = remainingObjBuf.unpack('CC')
        objId     = objHeader[0]
        objType   = objHeader[1]

        case objType
        when OBJTYPE_BYTE
          obj = OTAByte.from_w(remainingObjBuf)
        when OBJTYPE_INT
          obj = OTAInt.from_w(remainingObjBuf)
        when OBJTYPE_FLOAT
          obj = OTAFloat.from_w(remainingObjBuf)
        when OBJTYPE_STRING
          obj = OTAString.from_w(remainingObjBuf)
        when OBJTYPE_ARRAY_FLOAT
          obj = OTAFloatArray.from_w(remainingObjBuf)
        when OBJTYPE_ARRAY_BYTE
          obj = OTAByteArray.from_w(remainingObjBuf)
        when OBJTYPE_ARRAY_INT
          obj = OTAIntArray.from_w(remainingObjBuf)
        when OBJTYPE_TIMESTAMP
          obj = OTATimestamp.from_w(remainingObjBuf)
        else
          raise OTAException.new('Invalid object type in message at byte %d' % msgPtr)
        end

        @objects << obj

        msgPtr += obj.length
        remainingObjBuf = msg[msgPtr..msgLen]

      end

      msgCrc = msg[msgPtr].unpack('C')[0]
      objCrc  = crc(self.to_w(calc_crc = false))

      raise OTAException.new("CRC error") if msgCrc != objCrc

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