module M2M

  class OTAObject

    include OTACommon

    attr_accessor :id,:type,:size,:value

    def initialize(settings)
      @id,@type,@size,@value = settings[:id],expected_type,settings[:size],settings[:value]

      raise OTAException.new("Invalid nil value for #{self.class}") unless @value
    end

    def self.from_w(buffer)
      id,actual_type = buffer.unpack(OBJHEADER_FORMAT)
      raise OTAException.new("Invalid #{self} from wire - found #{OBJTYPE_LABELS[actual_type] || actual_type || 'nil'}") unless actual_type == expected_type

      value_offset = OBJHEADER_SIZE
      if OBJBODY_VARIABLE_TYPES[actual_type]
        length = buffer[value_offset,2].unpack('n')[0]
        value_offset += 2
      end

      case (value_format = OBJBODY_VALUE_FORMATS[actual_type])
        when String
          # do nothing
        when Hash
          scalar_size = buffer[value_offset,1].unpack('C')[0]
          raise OTAException.new("Invalid scalar size #{scalar_size} for #{self} from wire") unless value_format = value_format[scalar_size]
          value_offset += 1
        else
          raise OTAException.new("Value format not found for #{self}")
      end

      unpacked_value = unpack_value(buffer[value_offset,(length || 1) * (scalar_size || IMPLIED_SIZE_BY_FORMAT[value_format[0]] || 1)],value_format)

      new(:id => id,:size => scalar_size,:value => length ? unpacked_value : unpacked_value[0])
    end

    def self.unpack_value(buffer,format)
      buffer.unpack(format)
    end

    def self.expected_type
      raise OTAException.new("#{self}#expected_type not implemented")
    end

    def to_s
      parts = []
      parts << %(<object)
      parts << %(id="#{@id}")
      parts << %(type="#{OBJTYPE_LABELS[@type] || "unknown-#{@type}"}")
      parts << %(size="#{@size}") if @size
      parts << %(value="#{value_string}"/>)
      parts.join(' ')
    end

    def value_string
      @value.to_s
    end

    def to_w
      format = OBJHEADER_FORMAT
      preamble = [@id,@type]


      if OBJBODY_VARIABLE_TYPES[@type]
        format += 'n'
        preamble << @value.length
      end

      case (value_format = OBJBODY_VALUE_FORMATS[expected_type])
        when String
          format += value_format
        when Hash
          raise OTAException.new("Scalar size for #{self.class} required but not set") unless @size
          raise OTAException.new("Invalid scalar size #{@size} for #{self} in use") unless value_format = value_format[@size]

          format += "C#{value_format}"
          preamble << @size
        else
          raise OTAException.new("Value format not found for #{self.class}")
      end

      (preamble + Array(packable_value)).pack(format)
    end

    def packable_value
      @value
    end

    def expected_type
      self.class.expected_type
    end

    def length
      self.to_w.length
    end

  end

end