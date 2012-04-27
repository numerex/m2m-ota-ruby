Numerex Machine-to-Machine Over the Air Protocol [![Build Status](https://secure.travis-ci.org/spemmons/m2m-ota-ruby.png?branch=master)](http://travis-ci.org/spemmons/m2m-ota-ruby)
================================================

=== Installation

    git clone git@github.com:numerex/m2m-ota-ruby
    cd m2m-ota-ruby
    gem build m2m-ota.gemspec
    gem install m2m-ota-VERSION.gem

=== Example

    require 'm2m-ota'

    include M2M_OTA

    msg = OTA_Message.new(:messageType => MOBILE_ORIGINATED_EVENT,
                          :eventCode   => 20,
                          :sequenceId  => 20,
                          :timestamp   => M2M_OTA::current_timestamp)

    msg.autoObjectId = true # Generate incrementing object ids

    msg << OTA_Byte.new(0x11)
    msg << OTA_Int.new(0x40)
    msg << OTA_Float.new(79.5)
    msg << OTA_String.new("An abritrary string of arbitrary length")
    msg << OTA_Float_Array.new([1.0, 2.0, 100.0, 100000.0])
    msg << OTA_Byte_Array.new([0x10, 0x20, 0x30, 0xde, 0xed, 0xbe, 0xef])
    msg << OTA_Int_Array.new([1245, 4578, 10249, -9347, 8198 , 128000, 2147483647])
    msg << OTA_Timestamp.new(M2M_OTA::current_timestamp)

    msg_for_wire = msg.to_w

    puts "Sending " + msg.to_s




