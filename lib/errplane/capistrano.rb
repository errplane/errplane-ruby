require 'errplane'

Capistrano::Configuration.instance(:must_exist).load do
  after 'deploy',            'deploy:notify_errplane'
  after 'deploy:migrations', 'deploy:notify_errplane'

  namespace :deploy do
    desc 'Notify Errplane of the deployment'
    task :notify_errplane, :except => {:no_release => true} do
      set(:deploying_user) { `whoami`.strip }
      set(:deploying_user_name) { `bash -c 'git config --get user.name'`.strip }
      set(:deploying_user_email) { `bash -c 'git config --get user.email'`.strip }

      puts "Notifying Errplane of the deployment.."
      framework_env = fetch(:rails_env, fetch(:errplane_env, 'production'))
      load File.join(Dir.pwd, "config/initializers/errplane.rb")

      Errplane.configuration.logger = Logger.new("/dev/null")
      Errplane.configuration.rails_environment = framework_env

      deploy_options = {
        :environment => framework_env,
        :revision => current_revision,
        :repository => repository,
        :branch => (branch rescue nil),
        :scm => scm,
        :host => host,
        :remote_user => (user rescue nil),
        :local_user => deploying_user,
        :scm_user_name => deploying_user_name,
        :scm_user_email => deploying_user_email
      }

      Errplane::Transmitter.new.relay(deploy_options, true)
      puts 'Done.'
    end
  end
end
