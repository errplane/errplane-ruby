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

      deploy_options = {
        :framework_env => framework_env,
        :scm_revision => current_revision,
        :scm_repository => repository,
        :api_key => Errplane.configuration.api_key
      }
      Errplane::Deployment.new.announce!(deploy_options)
      puts 'Done.'
    end
  end
end
