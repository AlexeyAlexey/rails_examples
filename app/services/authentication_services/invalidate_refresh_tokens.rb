module AuthenticationServices
  class InvalidateRefreshTokens
    prepend ::ApplicationService

    def initialize(user_id:, refresh_token:, device:, reason:, drift_seconds: 0)
      @user_id = user_id
      @refresh_token = refresh_token
      @device = device
      @drift_seconds = drift_seconds
      @reason = reason
    end

    def call
      RefreshToken.create(user_id:,
                          device:,
                          token: digest_token,
                          action: 'invalidated',
                          reason:,
                          expire_at: DateTime.now.utc,
                          created_at:)
    end

    private

    attr_reader :user_id, :refresh_token, :device, :drift_seconds, :reason

    def created_at
      DateTime.now.utc + drift_seconds.seconds
    end

    def digest_token
      @digest_token ||= Digest::SHA256.hexdigest(refresh_token)
    end
  end
end
