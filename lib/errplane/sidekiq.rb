module Errplane
  class Sidekiq
    def call(worker, msg, queue)
      begin
        yield
      rescue => e
        Errplane.transmit_unless_ignorable(e, :custom_data => {:sidekiq => msg })
        raise(e)
      end
    end
  end
end

::Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add ::Errplane::Sidekiq
  end
end

