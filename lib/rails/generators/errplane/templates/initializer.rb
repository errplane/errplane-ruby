Errplane.configure do |config|
  config.api_key = "<%= api_key %>"
  config.application_id = "<%= application_id %>"
  #uncomment this if you want to push rails logs to errplane also
  #config.syslogd_port = "<%= Errplane.configuration.get_logport %>"
end

