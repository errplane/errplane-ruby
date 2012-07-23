module Errplane
  module Logger
    PREFIX = "[Errplane] "

    private
    def log(level, message)
      return if level != :error && !Errplane.configuration.debug?
      Errplane.configuration.logger.send(level, PREFIX + message) if Errplane.configuration.logger
    end
  end
end
