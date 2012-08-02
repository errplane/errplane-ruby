watch( '^lib/errplane/(.*)\.rb' )    { |m| build "rake spec" }
watch( '^spec/spec_helper\.rb' )  { |m| build "rake spec" }
watch( '^spec/unit/(.*)_spec\.rb' )  { |m| build "rake spec" }
watch( '^spec/integration/(.*)_spec\.rb' )  { |m| build "rake spec" }

# Signal.trap('QUIT') { build specs  } # Ctrl-\
Signal.trap('QUIT') { puts; build "rake spec"  } # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

def build(*paths)
  run "bundle exec #{paths.flatten.join(' ')}"
end

def specs
  Dir['spec/**/spec_*.rb'] - ['spec/spec_helper.rb']
end

def run( cmd )
  puts "Running `#{cmd}'"
  system cmd
end
