begin
  require 'errplane'
rescue LoadError
  raise "Can't find 'errplane' gem. Please add it to your Gemfile or install it."
end

module Resque
  module Failure
    class Errplane < Base
      def save
        ::Errplane.transmit_unless_ignorable(exception, :custom_data => {
          :resque => {
            :payload => payload,
            :worker => worker,
            :queue => queue
          }
        })
      end
    end
  end
end
