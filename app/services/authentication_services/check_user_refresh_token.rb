module AuthenticationServices
  class CheckUserRefreshToken
    prepend ::ApplicationService

    def initialize(device:, user_id:, refresh_token:, lifetime:)
      @device = device
      @user_id = user_id
      @refresh_token = refresh_token
      @lifetime = lifetime
    end

    def call
      # If you allow to use a couple of devices at the same time
      # you should take into account a device value in a db query ...
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

      refresh_tokens = RefreshToken.where('user_id = ? AND created_at >= ? AND created_at <= ?',
                                          user_id,
                                          DateTime.now.utc - lifetime.seconds,
                                          DateTime.now.utc + 10.seconds)
                                   .order(created_at: :desc)

      current_refresh_token, *rest_refresh_tokens = refresh_tokens

      prev_refresh_tokens = rest_refresh_tokens.find_all(&:not_expired?).map(&:token)

      if current_refresh_token.blank?
        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      if current_refresh_token.expired?
        user_readable_errors.add(:authentication, 'invalid credentials')

        return nil
      end

      if current_refresh_token.token != digest_token && prev_refresh_tokens.include?(digest_token)

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

    attr_reader :device, :user_id, :refresh_token, :lifetime

    def digest_token
      @digest_token ||= Digest::SHA256.hexdigest(refresh_token)
    end
  end
end
