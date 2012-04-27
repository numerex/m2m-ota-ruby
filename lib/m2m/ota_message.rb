module M2M

  class OTAMessage

    include OTACommon

    attr_accessor  :message_type, :event_code, :sequence_number,  :timestamp
    attr_accessor  :auto_id
    attr_reader    :major_version, :minor_version
    attr_reader    :objects

    def initialize(p={})

      if p[:data] then
        from_w p[:data]
      else
        @message_type  = p[:message_type] || 0
        @major_version = MAJOR_VERSION
        @minor_version = MINOR_VERSION
        @event_code    = p[:event_code]   || 0
        @sequence_number   = p[:sequence_number]  || 0
        @timestamp    = p[:timestamp]   || Time.now.to_i * 1000
        @objects      = []

        @auto_id = false
      end
    end

    # @return [String] Binary string header of the message
    def header
      version = (major_version << 4) | minor_version
      header = [message_type, version, event_code, sequence_number, htonq(timestamp)]
      header.pack('CCCnQ')
    end

    def <<(obj)
      raise OTAException.new('Invalid object added to message') if not obj.is_a? OTAObject
      @objects << obj
    end

    def to_w(calc_crc = true)
      message = header
      message += [@objects.length].pack('C')

      if @auto_id then
        auto_id = 1
        auto_set = lambda do |o|
          o.id = auto_id
          auto_id += 1
        end
      end
      @objects.each do |object|
        auto_set.call(object) if auto_set
        message += object.to_w
      end
      # Checksum byte
      message += [crc(message)].pack('C') if calc_crc
      message
    end

    def to_hex
      result = []
      self.to_w.each_byte{|byte| result << sprintf('%x', byte)}
      result.join
    end

    # @param [String] Binary string containing a received OTA message
    def from_w(message)
      header = message.unpack('CCCnQ')
      @message_type     = header[0]
      @major_version    = header[1] >> 4
      @minor_version    = header[1] & 0x0F
      @event_code       = header[2]
      @sequence_number  = header[3]
      @timestamp        = htonq(header[4])
      @objects          = []
      @auto_id          = 0


      message_length = message.length
      message_offset = 14 # First index of objects

      remaining_buffer = message[message_offset..message_length]
      while message_offset != message_length - 1
        obj_header = remaining_buffer.unpack('CC')
        obj_id     = obj_header[0]
        obj_type   = obj_header[1]

        case obj_type
          when OBJTYPE_BYTE
            obj = OTAByte.from_w(remaining_buffer)
          when OBJTYPE_INT
            obj = OTAInt.from_w(remaining_buffer)
          when OBJTYPE_FLOAT
            obj = OTAFloat.from_w(remaining_buffer)
          when OBJTYPE_STRING
            obj = OTAString.from_w(remaining_buffer)
          when OBJTYPE_ARRAY_FLOAT
            obj = OTAFloatArray.from_w(remaining_buffer)
          when OBJTYPE_ARRAY_BYTE
            obj = OTAByteArray.from_w(remaining_buffer)
          when OBJTYPE_ARRAY_INT
            obj = OTAIntArray.from_w(remaining_buffer)
          when OBJTYPE_TIMESTAMP
            obj = OTATimestamp.from_w(remaining_buffer)
          else
            raise OTAException.new('Invalid object type in message at byte %d' % message_offset)
        end

        @objects << obj

        message_offset += obj.length
        remaining_buffer = message[message_offset..message_length]

      end

      message_crc = message[message_offset].unpack('C')[0]
      obj_crc  = crc(self.to_w(false))

      raise OTAException.new("CRC error") if message_crc != obj_crc

    end

    def to_s
      [
        "<ota>\n",
        " <raw>#{to_hex}</raw>\n",
        " <header>\n",
        "  <type>#{@message_type}</type>\n",
        "  <version>\n",
        "   <major>#{@major_version}</major>\n",
        "   <minor>#{@minor_version}</minor>\n",
        "  </version>\n",
        "  <eventcode>#{@event_code}</eventcode>\n",
        "  <sequenceid>#{@sequence_number}</sequenceid>\n",
        "  <timestamp>#{@timestamp}</timestamp>\n",
        " </header>\n",
        " <objects>\n",
        *@objects.collect{|object| "   #{object}\n"},
        " </objects>\n",
        "</ota>\n",
      ].join
    end

  end

end