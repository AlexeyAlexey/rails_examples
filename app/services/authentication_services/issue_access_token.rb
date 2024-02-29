module AuthenticationServices
  class IssueAccessToken
    prepend ::ApplicationService

    RESERVED_ATTRS = [:sub, :exp, :jti, :aud, :iat].freeze

    def initialize(user_id:, expire_at:, opt_attrs: {})
      @user_id = user_id
      @opt_attrs = opt_attrs.delete_if { |key, _value| RESERVED_ATTRS.include?(key.to_sym) }
      @action = action
      @expire_at = expire_at
    end

    def call
      payload = { sub: 'rails_examples',
                  exp: expire_at.to_i,
                  jti:,
                  aud: user_id,
                  iat: DateTime.now.utc.to_i }

      payload = payload.merge(opt_attrs)

      JWT.encode payload,
                 ::AuthCredentials::AccessToken.private_key,
                 ::AuthCredentials::AccessToken.algorithm
    end

    private

    attr_reader :user_id, :opt_attrs, :action, :expire_at

    def jti
      @jti ||= SecureRandom.urlsafe_base64(42)
    end
  end
end
