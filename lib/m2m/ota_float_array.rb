require_relative 'ota_object'

module M2M

  class OTAFloatArray < OTAObject

    def initialize(value,size = SIZE_FLOAT_SINGLE,id = 0)
      value.class == Hash ? super(value) : super(:id => id,:size => size,:value => Array(value))
    end

    def self.expected_type
      OBJTYPE_ARRAY_FLOAT
    end

  end

end