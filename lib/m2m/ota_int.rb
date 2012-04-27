require_relative 'ota_object'

module M2M

  class OTAInt < OTAObject

    def initialize(value,size = SIZE_INT_LONG,id = 0)
      value.class == Hash ? super(value) : super(:id => id,:size => size,:value => value.to_i)
    end

    def self.expected_type
      OBJTYPE_INT
    end

  end

end