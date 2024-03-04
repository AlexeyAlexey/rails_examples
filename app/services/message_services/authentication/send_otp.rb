module MessageServices
  module Authentication
    class SendOtp
      prepend ::ApplicationService

      def initialize(code:, to:, type:)
        @code = code
        @to = to
        @type = type
      end

      def call
        case type.to_sym
        when :email

        when :sms

        when :push_notification
        else
        end
      end

      private

      attr_reader :code, :to, :type
    end
  end
end
