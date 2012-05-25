# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "errplane/version"

Gem::Specification.new do |s|
  s.name        = "errplane"
  s.version     = Errplane::VERSION
  s.authors     = ["Todd Persen"]
  s.email       = ["todd.persen@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "errplane"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_development_dependency "combustion"
  # s.add_runtime_dependency "rest-client"
end
