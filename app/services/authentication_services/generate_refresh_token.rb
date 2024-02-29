module AuthenticationServices
  class GenerateRefreshToken
    prepend ::ApplicationService

    def initialize(user_id:, device:, expire_at:)
      @user_id = user_id
      @device = device
      @expire_at = expire_at
    end

    def call
      payload = { sub: ::AuthCredentials::RefreshToken.subj,
                  exp: expire_at.to_i,
                  jti:,
                  aud: user_id,
                  iat: DateTime.now.utc.to_i,
                  device: }

      user_token = JWT.encode payload,
                              ::AuthCredentials::RefreshToken.private_key,
                              ::AuthCredentials::RefreshToken.algorithm

      cipher = OpenSSL::Cipher.new(::AuthCredentials::RefreshToken.cipher_options).encrypt

      cipher.key = ::AuthCredentials::RefreshToken.cipher_key

      user_encrypted_token = Base64.urlsafe_encode64(cipher.update(user_token) + cipher.final)

      token = ::AuthenticationServices::Helpers::RefreshTokenHelpers.generate_from(user_id:, device:, id: jti)

      response_object.new(user_token: user_encrypted_token, token:)
    end

    private

    attr_reader :user_id, :device, :expire_at

    def jti
      @jti ||= SecureRandom.urlsafe_base64(52)
    end

    def response_object
      @response_object ||= Struct.new(:user_token, :token)
    end
  end
end
