module AuthenticationServices
  module Helpers
    module RefreshTokenHelpers
      def self.generate_from(user_id:, device:, id:)
        "#{user_id}.#{device}.#{id}"
      end

      def self.select_from_paload(payload)
        generate_from(user_id: payload['aud'], device: payload['device'], id: payload['jti'])
      end
    end
  end
end
