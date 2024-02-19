module AuthenticationServices
  class RotateRefreshToken
    prepend ::ApplicationService

    def initialize(refresh_token:, expire_at:)
      @refresh_token = refresh_token
      @expire_at = expire_at
    end

    def call
      user_readable_errors.add(:authentication, 'invalid credentials') if refresh_token.blank?

      user_refresh_token = FindUserByRefreshToken.call(refresh_token:)

      if user_refresh_token.failure?
        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      device = user_refresh_token.result.device
      user_id = user_refresh_token.result.user_id

      res = CheckUserRefreshToken.call(device:, user_id:, refresh_token:)

      if res.failure?
        exceptions.add_multiple_errors res.exceptions if res.exceptions.present?

        if res.exceptions[:detected]&.include?('Reuse detection')
          res = InvalidateRefreshTokens.call(user_id:,
                                             refresh_token:,
                                             device:,
                                             drift_seconds: 2,
                                             reason: 'reuse detection')

          if res.failure?
            exceptions.add :exception, "[#{self.class.name}] tokens cannot be invalidated device: #{device}"
            exceptions.add_multiple_errors res.exceptions if res.exceptions.present?
          end
        end

        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      res = AuthenticationServices::IssueRefreshToken.call(user_id:,
                                                           action: 'rotated',
                                                           device:,
                                                           expire_at:)

      if res.failure?
        exceptions.add :exception, "[#{self.class.name}] a token cannot be issued device: #{device}"
        exceptions.add_multiple_errors res.exceptions if res.exceptions.present?

        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      res.result
    end

    private

    attr_reader :refresh_token, :expire_at
  end
end
