# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "errplane/version"

Gem::Specification.new do |s|
  s.name        = "errplane"
  s.version     = Errplane::VERSION
  s.authors     = ["Todd Persen"]
  s.email       = ["todd@errplane.com"]
  s.homepage    = "http://errplane.com"
  s.summary     = %q{Rails exception reporting for Errplane.}
  s.description = %q{This gem provides exception reporting with Errplane for Rails 3.x applications.}

  s.rubyforge_project = "errplane"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_development_dependency "combustion"
  # s.add_runtime_dependency "rest-client"
end
