module Errplane
  class BlackBox
    attr_reader :exception

    def initialize(params = {})
      @exception = params[:exception]
    end

    def to_json
      {
        :time => Time.now.to_i,
        :message => @exception.message,
        :backtrace => @exception.backtrace
      }.to_json
    end
  end
end
