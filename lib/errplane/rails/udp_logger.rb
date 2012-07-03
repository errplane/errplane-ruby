begin
	if( Errplane.configuration.syslogd_port && Errplane.configuration.syslogd_port != "")
	end
rescue => e
	puts "Failed to setup remote logger for Errplane! -#{e}"
end