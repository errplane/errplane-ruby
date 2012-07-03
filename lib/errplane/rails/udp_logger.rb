module Errplane
  class UdpLogger
    def initialize(port)
      @host = "syslogd.errplane.com"
      @port = port
     
      @syslog_p = SyslogProto::Packet.new

      local_hostname   = (Socket.gethostname rescue `hostname`.chomp)
      local_hostname   = 'localhost' if local_hostname.nil? || local_hostname.empty?
      @syslog_p.hostname = local_hostname

      @syslog_p.facility =  'user'
      @syslog_p.severity = 'notice'
      @udpsocket = UDPSocket.new
    end
    
    def write(message)
      message.split(/\r?\n/).each do |line|
        begin
          next if line =~ /^\s*$/
          pak = @syslog_p.dup
          pak.msg = line
          @udpsocket.send(pak.assemble, 0, @host, @port)
        rescue => e
          puts e
          puts e.backtrace
        	#ignore errors
        end
      end
    end
        
    def close
      @udpsocket.close
    end
  end
end

begin
	if( Errplane.configuration.syslogd_port && Errplane.configuration.syslogd_port != "")
		require "uri"
		require 'socket'
		require 'errplane/syslogproto'

		puts "Setting up Errplane remote logger on port -#{Errplane.configuration.syslogd_port}"
		logger = Logger.new(Errplane::UdpLogger.new( Errplane.configuration.syslogd_port.to_i))
		logger.level = Logger::INFO

    logger.error "TEST"
		Rails.logger = Rails.application.config.logger = ActionController::Base.logger = Rails.cache.logger = logger
	end
rescue => e
	puts "Failed to setup remote logger for Errplane! -#{e}"
end
