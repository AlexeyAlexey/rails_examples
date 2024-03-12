module AuthenticationServices
  class InvalidateRefreshTokens
    prepend ::ApplicationService

    def initialize(user_id:,
                   refresh_token:,
                   device:,
                   reason:,
                   action: RefreshToken::ACTIONS['invalidated'],
                   drift_seconds: 0)
      @user_id = user_id
      @refresh_token = refresh_token
      @device = device
      @reason = reason
      @action = action
      @drift_seconds = drift_seconds
    end

    def call
      RefreshToken.create(user_id:,
                          device:,
                          token: digest_token,
                          action:,
                          reason:,
                          expire_at: DateTime.now.utc,
                          created_at:)
    end

    private

    attr_reader :user_id, :refresh_token, :device, :reason, :action, :drift_seconds

    def created_at
      DateTime.now.utc + drift_seconds.seconds
    end

    def digest_token
      @digest_token ||= Digest::SHA256.hexdigest(refresh_token)
    end
  end
end
