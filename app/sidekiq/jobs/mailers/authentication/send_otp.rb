module Jobs
  module Mailers
    module Authentication
      class SendOtp
        include Sidekiq::Job
        sidekiq_options queue: 'critical'

        def perform(code, user_email_id)
          # user_email = UserEmail.find(user_email_id)
        end
      end
    end
  end
end
