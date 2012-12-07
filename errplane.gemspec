# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "errplane/version"

Gem::Specification.new do |s|
  s.name        = "errplane"
  s.version     = Errplane::VERSION
  s.authors     = ["Todd Persen"]
  s.email       = ["todd@errplane.com"]
  s.homepage    = "http://errplane.com"
  s.summary     = %q{Rails-based instrumentation library for Errplane.}
  s.description = %q{This gem provides implements instrumentation with Errplane for Rails 3.x applications.}

  s.rubyforge_project = "errplane"

  s.files         = Dir.glob('lib/**/*.rb') + %w(README.md)
  s.test_files    = Dir.glob('test/**/*.rb') + Dir.glob('spec/**/*.rb') + Dir.glob('features/**/*.rb')
  s.executables   = Dir.glob('bin/**/*.rb').map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.licenses = ['MIT']

  s.add_runtime_dependency 'json'

  s.add_dependency 'activesupport', ['>= 2.3.4']
  s.add_dependency 'actionpack', ['>= 2.3.4']
  s.add_development_dependency 'bundler', ['>= 1.0.0']
  s.add_development_dependency 'fakeweb', ['>= 0']
  s.add_development_dependency 'guard', ['>= 0']
  s.add_development_dependency 'guard-rspec', ['>= 0']
  s.add_development_dependency 'rake', ['>= 0']
  s.add_development_dependency 'rdoc', ['>= 0']
  s.add_development_dependency 'rspec', ['>= 0']
  s.add_development_dependency 'tzinfo', ['>= 0']
end
