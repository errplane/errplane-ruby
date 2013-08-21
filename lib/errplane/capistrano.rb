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
      framework_env = fetch(:errplane_env, fetch(:rails_env, 'production'))

      unless defined?(Rails)
        class Rails
          @env = "production";
          def self.env; return self; end
          def self.env=(env); @env = env; end
          def self.to_s; @env; end
          def self.method_missing(m, *args, &block); return m.to_s == "#{@env}?"; end
        end
        Rails.env = framework_env
      end
      begin
        load File.join(Dir.pwd, "config/initializers/errplane.rb")
      rescue
        puts "Couldn't find default initializer for Errplane, continuing anyhow."
      end

      Errplane.configuration.logger = Logger.new("/dev/null")
      Errplane.configuration.environment = framework_env

      context = {
        :environment => framework_env,
        :revision => current_revision,
        :repository => repository,
        :branch => (branch rescue nil),
        :scm => scm,
        :remote_user => (user rescue nil),
        :local_user => deploying_user,
        :scm_user_name => deploying_user_name,
        :scm_user_email => deploying_user_email
      }

      Errplane.report_deployment(context)
    end
  end
end
