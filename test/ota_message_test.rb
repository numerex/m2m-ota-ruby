require_relative 'test_helper'

module M2M

  class OTAMessageTest < Test::Unit::TestCase

    include OTACommon

    def testMessageProperties

      timestamp = Time.now.to_i * 1000
      f = M2M::OTAMessage.new(:timestamp => timestamp)
      assert_equal(0, f.message_type)
      assert_equal(1, f.major_version)
      assert_equal(0, f.minor_version)
      assert_equal(0, f.event_code)
      assert_equal(0, f.sequence_number)
      assert_equal(timestamp, f.timestamp)

    end

    def testMessageProperties2

      f = M2M::OTAMessage.new
      n = Time.now.to_i * 1000 # In milliseconds

      f.message_type = MOBILE_ORIGINATED_EVENT
      f.event_code = 0x66
      f.sequence_number = 100
      f.timestamp = n

      assert_equal(MOBILE_ORIGINATED_EVENT, f.message_type)
      assert_equal(MAJOR_VERSION, f.major_version)
      assert_equal(MINOR_VERSION, f.minor_version)
      assert_equal(0x66, f.event_code)
      assert_equal(100, f.sequence_number)
      assert_equal(n, f.timestamp)

    end


    def testMessageHeader

      f = M2M::OTAMessage.new
      header = f.header()
      header = header.unpack('CCCSL')

      majorVersion = (header[1] >> 4) & 0x0f
      minorVersion = header[1] & 0x0f

      assert_equal(0, header[0])
      assert_equal(MAJOR_VERSION, majorVersion)
      assert_equal(MINOR_VERSION, minorVersion)

    end

    def testAddObjects

      msg = M2M::OTAMessage.new
      msg.message_type = MOBILE_ORIGINATED_EVENT
      msg.event_code = 20
      msg.sequence_number = 50
      msg.timestamp = Time.now.to_i * 1000

      puts msg.timestamp

      msg << OTAFloat.new(79.5, 4, 1)
      msg << OTAString.new("Temperature", 2)
      msg << OTATimestamp.new(current_timestamp)

      puts msg.to_w.hexdump()

    end

    def testAutoset

      msg = M2M::OTAMessage.new(:message_type => MOBILE_ORIGINATED_EVENT,
                           :event_code => 10,
                           :sequence_number => 1)

      msg.auto_id = true

      msg << OTAByte.new(7)
      msg << OTAString.new("This is a string")
      msg << OTAFloatArray.new([2.1, 3.4, 1.8, 5.5, 6.2, 9.4])
      msg << OTAIntArray.new([1245, 4578, 10249, -9347, 8198, 128000, 2147483647])
      msg << OTAInt.new(0xaa)
      msg << OTAInt.new(0xbbcc)
      msg << OTAInt.new(0xddeeff)
      msg << OTAInt.new(0xdeadbeef)
      puts msg.to_w.hexdump()
      puts msg.to_s

    end

    def testReference
      msg = M2M::OTAMessage.new(:message_type => MOBILE_ORIGINATED_EVENT,
                           :event_code => 20,
                           :sequence_number => 20,
                           :timestamp => 0xff)
      msg.auto_id = true

      msg << OTAByte.new(0x11)

      puts msg.to_w.hexdump()
      puts msg.to_s
    end

    def testFromWire

      puts "-- testFromWire --"

      msg = M2M::OTAMessage.new(:message_type => MOBILE_ORIGINATED_EVENT,
                           :event_code => 20,
                           :sequence_number => 20,
                           :timestamp => 0xff)
      msg.auto_id = true

      msg << OTAByte.new(0x11)
      msg << OTAInt.new(0x40)
      msg << OTAFloat.new(79.5)
      msg << OTAString.new("An abritrary string of arbitrary length")
      msg << OTAFloatArray.new([1.0, 2.0, 100.0, 100000.0])
      msg << OTAByteArray.new([0x10, 0x20, 0x30, 0xde, 0xed, 0xbe, 0xef])
      msg << OTAIntArray.new([1245, 4578, 10249, -9347, 8198, 128000, 2147483647])
      msg << OTATimestamp.new(current_timestamp)

      puts "Constructed Message -->"
      puts msg.to_w.hexdump()
      puts msg.to_s


      wireMsg = M2M::OTAMessage.new(:data => msg.to_w)
      puts "Wire Message --->"
      puts wireMsg.to_w.hexdump()
      puts wireMsg.to_s

      assert_equal(msg.to_w, wireMsg.to_w)

    end

  end

end