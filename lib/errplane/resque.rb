module Resque
  module Failure
    class Errplane < Base
      def save
        Errplane.transmit_unless_ignorable(exception, :custom_data => {
          :resque => {
            :payload => {
              :class => payload['class'].to_s,
              :args => payload['args'].inspect
            },
            :worker => worker,
            :queue => queue
          }
        })
      end
    end
  end
end
