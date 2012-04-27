require_relative 'ota_object'

module M2M

  class OTAString < OTAObject

    def initialize(value, id = 0)
      if value.class == Hash
        value[:value] = Array(value[:value]).join
        super(value)
      else
        super(:id => id,:value => value.to_s)
      end
    end

    def self.expected_type
      OBJTYPE_STRING
    end

  end

end