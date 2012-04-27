require_relative 'ota_object'

module M2M

  class OTAByte < OTAObject

    def initialize(value,id = 0)
      value.class == Hash ? super(value) : super(:id => id,:value => value.to_i)
    end

    def self.expected_type
      OBJTYPE_BYTE
    end

  end

end