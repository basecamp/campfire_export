module CampfireExport
  class Exception < StandardError

    attr_reader :resource, :message, :code

    def initialize(resource, message, code=nil)
      @resource = resource
      @message  = message
      @code     = code
    end

    def to_s
      "<#{resource}>: #{message}" + (code ? " (#{code})" : "")
    end
  end
end
