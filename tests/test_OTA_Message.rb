require 'm2m-ota'
require 'test/unit'
require 'hexdump'

include M2M_OTA

class TestOTAMessage < Test::Unit::TestCase

  def testMessageProperties

    timestamp = Time.now.to_i * 1000
    f = OTA_Message.new(:timestamp => timestamp)
    assert_equal(0, f.messageType)
    assert_equal(1, f.majorVersion)
    assert_equal(0, f.minorVersion)
    assert_equal(0, f.eventCode)
    assert_equal(0, f.sequenceId)
    assert_equal(timestamp, f.timestamp)

  end

  def testMessageProperties2

    f = OTA_Message.new
    n = Time.now.to_i * 1000  # In milliseconds

    f.messageType = MOBILE_ORIGINATED_EVENT
    f.eventCode   = 0x66
    f.sequenceId  = 100
    f.timestamp   = n

    assert_equal(MOBILE_ORIGINATED_EVENT, f.messageType)
    assert_equal(MAJOR_VERSION, f.majorVersion)
    assert_equal(MINOR_VERSION, f.minorVersion)
    assert_equal(0x66, f.eventCode)
    assert_equal(100,  f.sequenceId)
    assert_equal(n, f.timestamp)

  end


  def testMessageHeader

    f = OTA_Message.new
    header = f.header()
    header = header.unpack('CCCSL')

    majorVersion = (header[1] >> 4) & 0x0f
    minorVersion = header[1]        & 0x0f

    assert_equal(0, header[0])
    assert_equal(MAJOR_VERSION, majorVersion)
    assert_equal(MINOR_VERSION, minorVersion)

  end

  def testAddObjects

    msg = OTA_Message.new
    msg.messageType = MOBILE_ORIGINATED_EVENT
    msg.eventCode   = 20
    msg.sequenceId  = 50
    msg.timestamp   = Time.now.to_i * 1000

    puts msg.timestamp

    msg << OTA_Float.new(79.5, 1)
    msg << OTA_String.new("Temperature", 2)
    msg << OTA_Timestamp.new(timestamp)

    puts msg.to_w.hexdump()

  end

  def testAutoset

    msg = OTA_Message.new(:messageType => MOBILE_ORIGINATED_EVENT,
                          :eventCode   => 10,
                          :sequenceId  => 1)

    msg.autoObjectId = true

    msg << OTA_Byte.new(7)
    msg << OTA_String.new("This is a string")
    msg << OTA_Float_Array.new([2.1, 3.4, 1.8, 5.5, 6.2, 9.4])
    msg << OTA_Int_Array.new([1245, 4578, 10249, -9347, 8198 , 128000, 2147483647])
    msg << OTA_Int.new(0xaa)
    msg << OTA_Int.new(0xbbcc)
    msg << OTA_Int.new(0xddeeff)
    msg << OTA_Int.new(0xdeadbeef)
    puts msg.to_w.hexdump()
    puts msg.to_s

  end

  def testReference
    msg = OTA_Message.new(:messageType => MOBILE_ORIGINATED_EVENT,
                          :eventCode   => 20,
                          :sequenceId  => 20,
                          :timestamp   => 0xff)
    msg.autoObjectId = true

    msg << OTA_Byte.new(0x11)

    puts msg.to_w.hexdump()
    puts msg.to_s
  end

  def testFromWire

    puts "-- testFromWire --"

    msg = OTA_Message.new(:messageType => MOBILE_ORIGINATED_EVENT,
                          :eventCode   => 20,
                          :sequenceId  => 20,
                          :timestamp   => 0xff)
    msg.autoObjectId = true

    now = timestamp

    msg << OTA_Byte.new(0x11)
    msg << OTA_Int.new(0x40)
    msg << OTA_Float.new(79.5)
    msg << OTA_String.new("An abritrary string of arbitrary length")
    msg << OTA_Float_Array.new([1.0, 2.0, 100.0, 100000.0])
    msg << OTA_Byte_Array.new([0x10, 0x20, 0x30, 0xde, 0xed, 0xbe, 0xef])
    msg << OTA_Int_Array.new([1245, 4578, 10249, -9347, 8198 , 128000, 2147483647])
    msg << OTA_Timestamp.new(timestamp)

    puts "Constructed Message -->"
    puts msg.to_w.hexdump()
    puts msg.to_s


    wireMsg = OTA_Message.new(:data => msg.to_w)
    puts "Wire Message --->"
    puts wireMsg.to_w.hexdump()
    puts wireMsg.to_s

    assert_equal(msg.to_w, wireMsg.to_w)

  end


end
