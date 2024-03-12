module MessageServices
  module Authentication
    class SendOtp
      prepend ::ApplicationService

      def initialize(code:, objct_id:, type:)
        @code = code
        @objct_id = objct_id
        @type = type
      end

      def call
        case type.to_sym
        when :email
          ::Jobs::Mailers::Authentication::SendOtp.perform_async(code, objct_id)

        when :sms
          ::Jobs::Mailers::Authentication::Twilio.perform_async(code, objct_id)
        end
      end

      private

      attr_reader :code, :objct_id, :type
    end
  end
end
