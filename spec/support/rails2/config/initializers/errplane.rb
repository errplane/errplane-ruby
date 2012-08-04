Errplane.configure do |config|
  config.api_key = "f123-e456-d789c012"
  config.application_id = "b12r8c72"
end

MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]
