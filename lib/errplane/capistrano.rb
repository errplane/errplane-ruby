require 'errplane'

Capistrano::Configuration.instance(:must_exist).load do
  after 'deploy',            'deploy:notify_errplane'
  after 'deploy:migrations', 'deploy:notify_errplane'

  namespace :deploy do
    desc 'Notify Errplane of the deployment'
    task :notify_errplane, :except => {:no_release => true} do
      puts "Notifying Errplane of the deployment.."
      framework_env = fetch(:rails_env, fetch(:errplane_env, 'production'))
      load File.join(Dir.pwd, "config/initializers/errplane.rb")
      Errplane.configuration.rails_environment = framework_env

      deploy_options = {
        :environment => framework_env,
        :revision => current_revision,
        :repository => repository,
        :scm => scm,
        :host => host
      }
      Errplane::Transmitter.new.relay(deploy_options, true)
      puts 'Done.'
    end
  end
end
