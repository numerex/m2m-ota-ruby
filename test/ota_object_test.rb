require_relative 'test_helper'

module M2M

  class OTAObjectTest < Test::Unit::TestCase

    include OTACommon

    class Tester < OTAObject

      def self.expected_type
        255
      end

    end

    def test_ota_object
      exception = assert_raise M2M::OTAException do OTAObject.new({}) end
      assert_equal 'M2M::OTAObject#expected_type not implemented',exception.to_s

      exception = assert_raise M2M::OTAException do Tester.new({}) end
      assert_equal 'Invalid nil value for M2M::OTAObjectTest::Tester',exception.to_s

      exception = assert_raise M2M::OTAException do Tester.from_w([1,1].pack(OBJHEADER_FORMAT)) end
      assert_equal 'Invalid M2M::OTAObjectTest::Tester from wire - found int',exception.to_s

      exception = assert_raise M2M::OTAException do Tester.from_w([1,Tester.expected_type].pack(OBJHEADER_FORMAT)) end
      assert_equal 'Value format not found for M2M::OTAObjectTest::Tester',exception.to_s

      assert_equal %(<object id="1" type="unknown-255" value="2"/>),(tester = Tester.new(:id => 1,:value => 2)).to_s
      exception = assert_raise M2M::OTAException do tester.to_w end
      assert_equal 'Value format not found for M2M::OTAObjectTest::Tester',exception.to_s
    end

    def test_ota_byte
      assert_equal %(<object id="2" type="byte" value="1"/>),(tester = OTAByte.new(1,2)).to_s
      assert_equal %(\x02\x00\x01),tester.to_w
      assert_equal 3,tester.length
      assert_equal %(<object id="2" type="byte" value="1"/>),OTAByte.from_w(tester.to_w).to_s
    end

    def test_ota_byte_array
      assert_equal %(<object id="4" type="array[byte]" value="[1, 2, 3]"/>),(tester = OTAByteArray.new([1,2,3],4)).to_s
      assert_equal %(\x04\x05\x00\x03\x01\x02\x03),tester.to_w
      assert_equal 7,tester.length
      assert_equal %(<object id="4" type="array[byte]" value="[1, 2, 3]"/>),OTAByteArray.from_w(tester.to_w).to_s
    end

    def test_ota_float
      assert_equal %(<object id="0" type="float" size="4" value="1.0"/>),(tester = OTAFloat.new(1,SIZE_FLOAT_SINGLE)).to_s
      assert_equal %(\x00\x03\x04?\x80\x00\x00),tester.to_w
      assert_equal 7,tester.length
      assert_equal %(<object id="0" type="float" size="4" value="1.0"/>),OTAFloat.from_w(tester.to_w).to_s

      assert_equal %(<object id="0" type="float" size="8" value="1.0"/>),(tester = OTAFloat.new(1,SIZE_FLOAT_DOUBLE)).to_s
      assert_equal %(\x00\x03\x08?\xF0\x00\x00\x00\x00\x00\x00),tester.to_w
      assert_equal 11,tester.length
      assert_equal %(<object id="0" type="float" size="8" value="1.0"/>),OTAFloat.from_w(tester.to_w).to_s
    end

    def test_ota_float_array
      assert_equal %(<object id="0" type="array[float]" size="4" value="[1.0, 2.0, 3.0]"/>),(tester = OTAFloatArray.new([1.0,2.0,3.0])).to_s
      assert_equal %(\x00\x07\x00\x03\x04?\x80\x00\x00@\x00\x00\x00@@\x00\x00),tester.to_w
      assert_equal 17,tester.length
      assert_equal %(<object id="0" type="array[float]" size="4" value="[1.0, 2.0, 3.0]"/>),OTAFloatArray.from_w(tester.to_w).to_s

      assert_equal %(<object id="0" type="array[float]" size="8" value="[1.0, 2.0, 3.0]"/>),(tester = OTAFloatArray.new([1.0,2.0,3.0],SIZE_FLOAT_DOUBLE)).to_s
      assert_equal %(\x00\x07\x00\x03\x08?\xF0\x00\x00\x00\x00\x00\x00@\x00\x00\x00\x00\x00\x00\x00@\b\x00\x00\x00\x00\x00\x00),tester.to_w
      assert_equal 29,tester.length
      assert_equal %(<object id="0" type="array[float]" size="8" value="[1.0, 2.0, 3.0]"/>),OTAFloatArray.from_w(tester.to_w).to_s
    end

    def test_ota_int
      assert_equal %(<object id="0" type="int" size="4" value="1"/>),(tester = OTAInt.new(1)).to_s
      assert_equal %(\x00\x01\x04\x00\x00\x00\x01),tester.to_w
      assert_equal 7,tester.length
      assert_equal %(<object id="0" type="int" size="4" value="1"/>),OTAInt.from_w(tester.to_w).to_s

      assert_equal %(<object id="0" type="int" size="2" value="1"/>),(tester = OTAInt.new(1,SIZE_INT_SHORT)).to_s
      assert_equal %(\x00\x01\x02\x00\x01),tester.to_w
      assert_equal 5,tester.length
      assert_equal %(<object id="0" type="int" size="2" value="1"/>),OTAInt.from_w(tester.to_w).to_s

      assert_equal %(<object id="0" type="int" size="1" value="1"/>),(tester = OTAInt.new(1,SIZE_INT_TINY)).to_s
      assert_equal %(\x00\x01\x01\x01),tester.to_w
      assert_equal 4,tester.length
      assert_equal %(<object id="0" type="int" size="1" value="1"/>),OTAInt.from_w(tester.to_w).to_s
    end

    def test_ota_int_array
      assert_equal %(<object id="0" type="array[int]" size="4" value="[1, 2, 3]"/>),(tester = OTAIntArray.new([1,2,3])).to_s
      assert_equal %(\x00\x06\x00\x03\x04\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x03),tester.to_w
      assert_equal 17,tester.length
      assert_equal %(<object id="0" type="array[int]" size="4" value="[1, 2, 3]"/>),OTAIntArray.from_w(tester.to_w).to_s

      assert_equal %(<object id="0" type="array[int]" size="2" value="[1, 2, 3]"/>),(tester = OTAIntArray.new([1,2,3],SIZE_INT_SHORT)).to_s
      assert_equal %(\x00\x06\x00\x03\x02\x00\x01\x00\x02\x00\x03),tester.to_w
      assert_equal 11,tester.length
      assert_equal %(<object id="0" type="array[int]" size="2" value="[1, 2, 3]"/>),OTAIntArray.from_w(tester.to_w).to_s

      assert_equal %(<object id="0" type="array[int]" size="1" value="[1, 2, 3]"/>),(tester = OTAIntArray.new([1,2,3],SIZE_INT_TINY)).to_s
      assert_equal %(\x00\x06\x00\x03\x01\x01\x02\x03),tester.to_w
      assert_equal 8,tester.length
      assert_equal %(<object id="0" type="array[int]" size="1" value="[1, 2, 3]"/>),OTAIntArray.from_w(tester.to_w).to_s
    end

    def test_ota_string
      assert_equal %(<object id="0" type="string" value="ABC"/>),(tester = OTAString.new('ABC')).to_s
      assert_equal %(\x00\x02\x00\x03ABC),tester.to_w
      assert_equal 7,tester.length
      assert_equal %(<object id="0" type="string" value="ABC"/>),OTAString.from_w(tester.to_w).to_s
    end

    def test_ota_timestamp
      time = Time.utc(2001,1,1)
      assert_equal %(<object id="0" type="timestamp" value="978307200000"/>),(tester = OTATimestamp.new(time)).to_s
      assert_equal %(\x00\x04\x00\x00\x00\xE3\xC7\xA74\x00),tester.to_w
      assert_equal 10,tester.length
      assert_equal %(<object id="0" type="timestamp" value="978307200000"/>),OTATimestamp.from_w(tester.to_w).to_s
    end

  end

end