module AuthenticationServices
  class CheckUserRefreshToken
    prepend ::ApplicationService

    def initialize(device:, user_id:, refresh_token:)
      @device = device
      @user_id = user_id
      @refresh_token = refresh_token
    end

    def call
      if refresh_token.blank?
        exceptions.add :invalid_parameters, 'refresh_token is blank?'
        return nil
      end
      if user_id.blank?
        exceptions.add :invalid_parameters, 'user_id is blank?'
        return nil
      end
      if device.blank?
        exceptions.add :invalid_parameters, 'device is blank?'
        return nil
      end

      refresh_tokens = RefreshToken.where(device:, user_id:).order(created_at: :desc).limit(2)

      current_refresh_token, prev_refresh_token = refresh_tokens

      if current_refresh_token.blank?
        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      if current_refresh_token.token != digest_token && prev_refresh_token&.token == digest_token

        exceptions.add :detected, 'Reuse detection' if current_refresh_token.action != 'sing_in'

        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      if current_refresh_token.token != digest_token
        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      if current_refresh_token.illegal?
        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      refresh_token
    end

    private

    attr_reader :device, :user_id, :refresh_token

    def digest_token
      @digest_token ||= Digest::SHA256.hexdigest(refresh_token)
    end
  end
end
