require_relative 'ota_object'

module M2M

  class OTAByteArray < OTAObject

    def initialize(value,id = 0)
      value.class == Hash ? super(value) : super(:id => id,:value => Array(value))
    end

    def self.expected_type
      OBJTYPE_ARRAY_BYTE
    end

  end

end