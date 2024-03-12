module Jobs
  module Twilio
    module Authentication
      class SendOtp
        sidekiq_options queue: 'critical'

        def perform(_code, _objct_id); end
      end
    end
  end
end
