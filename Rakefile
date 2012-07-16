# encoding: utf-8

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => "spec:all"

namespace :spec do
  %w(rails_3.2 rails_3.1 rails_3.0 rails_2.3 sinatra).each do |gemfile|
    desc "Run Tests against #{gemfile}"
    task gemfile do
      sh "BUNDLE_GEMFILE='gemfiles/#{gemfile}.gemfile' bundle --quiet"
      sh "BUNDLE_GEMFILE='gemfiles/#{gemfile}.gemfile' bundle exec rake -t spec"
    end
  end

  desc "Run Tests against all ORMs"
  task :all do
    %w(rails_3.2 rails_3.1 rails_3.0 rails_2.3 sinatra).each do |gemfile|
      sh "BUNDLE_GEMFILE='gemfiles/#{gemfile}.gemfile' bundle --quiet"
      sh "BUNDLE_GEMFILE='gemfiles/#{gemfile}.gemfile' bundle exec rake spec"
    end
  end
end

# require 'rdoc/task'

# Rake::RDocTask.new do |rdoc|
  # require 'errplane/version'

  # rdoc.rdoc_dir = 'rdoc'
  # rdoc.title = "Errplane #{Errplane::VERSION}"
  # rdoc.rdoc_files.include('README*')
  # rdoc.rdoc_files.include('lib/**/*.rb')
# end
