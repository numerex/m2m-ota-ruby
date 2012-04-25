require 'OTA_Message'
require 'test/unit'

require 'hexdump'

include M2M_OTA

class TestOTAMessage < Test::Unit::TestCase

  def testMessageProperties

    f = OTA_Message.new
    assert_equal(0, f.messageType)
    assert_equal(1, f.majorVersion)
    assert_equal(0, f.minorVersion)
    assert_equal(0, f.eventCode)
    assert_equal(0, f.sequenceId)
    assert_equal(0, f.timestamp)

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

    msg.add_float  1, 79.5
    msg.add_string 2, "Temperature"

    puts msg.to_w.hexdump()

  end


end
