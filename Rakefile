# encoding: utf-8

if ENV["BUNDLE_GEMFILE"] == File.expand_path("Gemfile")
  ENV["BUNDLE_GEMFILE"] = "gemfiles/Gemfile.rails-3.2.x"
end

require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = FileList['spec/**/*_spec.rb']
  end

  RSpec.configure do |config|
    config.color_enabled = true
    config.tty = true
    config.formatter = :documentation
    config.mock_with :rr
  end
rescue LoadError
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new(:spec) do |t|
    t.pattern = FileList['spec/**/*_spec.rb']
  end
end
