module AuthenticationServices
  class IssueRefreshToken
    prepend ::ApplicationService

    def initialize(user_id:, device:, expire_at:, action: 'issued')
      @user_id = user_id
      @device = device
      @action = action
      @expire_at = expire_at
    end

    def call
      ActiveRecord::Base.transaction do
        created_at = DateTime.now.utc

        UserRefreshToken.create(user_id:,
                                token: digest_token,
                                device:,
                                created_at:)

        RefreshToken.create(user_id:,
                            token: digest_token,
                            device:,
                            action:,
                            expire_at:,
                            created_at:)
      end

      token
    end

    private

    attr_reader :user_id, :device, :action, :expire_at

    def token
      @token ||= SecureRandom.urlsafe_base64(52)
    end

    def digest_token
      @digest_token ||= Digest::SHA256.hexdigest(token)
    end
  end
end
