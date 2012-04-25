module M2M

  module OTACommon

    MOBILE_ORIGINATED_EVENT = 0xAA
    MOBILE_ORIGINATED_ACK   = 0xBB
    MOBILE_TERMINATED_EVENT = 0xCC
    MOBILE_TERMINATED_ACK   = 0xDD

    OBJTYPE_BYTE            = 0
    OBJTYPE_INT             = 1
    OBJTYPE_STRING          = 2
    OBJTYPE_FLOAT           = 3
    OBJTYPE_TIMESTAMP       = 4
    OBJTYPE_ARRAY_BYTE      = 5
    OBJTYPE_ARRAY_INT       = 6
    OBJTYPE_ARRAY_FLOAT     = 7

    SIZE_OF_FLOAT           = 4
    SIZE_OF_TIMESTAMP       = 8

    MAJOR_VERSION           = 1
    MINOR_VERSION           = 0

    MESSAGE_TYPE_POS         = 0
    PROTOCOL_VERSION_POS     = 1
    EVENT_CODE_POS           = 2
    SEQ_ID_POS               = 3
    TIMESTAMP_POS            = 5

    MAX_PACKET_SIZE          = 1024

    IS_BIG_ENDIAN           = [1].pack('s') == [1].pack('n')


    class OTAException < Exception
    end

    def crc(data)
      _m = 0
      _p = 0
      _r = data[0].unpack('C')[0]

      indexes = (1..data.length - 1)
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

    def htonq val
      IS_BIG_ENDIAN ? val : ([val].pack('Q').reverse.unpack('Q').first)
    end

    def current_timestamp
      Time.now.to_i * 1000
    end

  end

end

Dir["#{File.dirname(__FILE__)}/m2m/*.rb"].each{|file| require file}