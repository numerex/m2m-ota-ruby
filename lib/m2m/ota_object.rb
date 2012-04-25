module M2M

  class OTAObject

    include OTACommon

    attr_accessor :objId, :objValue

    def initialize(objValue, objId = 0)
      @objId    = objId
      @objValue = objValue
    end

    def to_w
      raise OTAException.new('#to_w not implemented')
    end

    def length
      self.to_w.length
    end

  end

end