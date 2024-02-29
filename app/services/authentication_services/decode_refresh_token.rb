module AuthenticationServices
  class DecodeRefreshToken
    prepend ::ApplicationService

    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      decoded_refresh_token = {}

      begin
        decoded_refresh_token = Base64.urlsafe_decode64(refresh_token)

        decipher = OpenSSL::Cipher.new(::AuthCredentials::RefreshToken.cipher_options).decrypt

        decipher.key = AuthCredentials::RefreshToken.cipher_key

        decoded_refresh_token = decipher.update(decoded_refresh_token) + decipher.final

        decoded_refresh_token, _rest = JWT.decode decoded_refresh_token,
                                                  ::AuthCredentials::RefreshToken.private_key,
                                                  true,
                                                  { algorithm: ::AuthCredentials::RefreshToken.algorithm,
                                                    sub: ::AuthCredentials::RefreshToken.subj,
                                                    verify_sub: true,
                                                    verify_jti: true,
                                                    verify_iat: true,
                                                    verify_aud: true }
      rescue JWT::InvalidJtiError
        exceptions.add :jwt, 'Invalid jti'
      rescue JWT::InvalidIatError
        exceptions.add :jwt, 'Invalid iat'
      rescue JWT::InvalidSubError
        exceptions.add :jwt, 'Invalid sub'
      rescue JWT::InvalidAudError
        exceptions.add :jwt, 'Invalid aud'
      rescue JWT::DecodeError
        exceptions.add :jwt, 'Decode Error'
      rescue JWT::VerificationError
        exceptions.add :jwt, 'Verification Error'
      rescue JWT::ExpiredSignature
        exceptions.add :jwt, 'Expired Signature'
      rescue ArgumentError
        exceptions.add :refresh_token, 'Invalid Format'
      rescue StandardError => e
        exceptions.add :error, e.message
      end

      return nil if exceptions.present?

      if decoded_refresh_token['device'].blank?
        exceptions.add :device, 'Device value is not present'

        return nil
      end

      response_object.new(user_id: decoded_refresh_token['aud'],
                          device: decoded_refresh_token['device'],
                          token: ::AuthenticationServices::Helpers::RefreshTokenHelpers
                             .select_from_paload(decoded_refresh_token))
    end

    private

    attr_reader :refresh_token

    def response_object
      @response_object ||= Struct.new(:user_id, :device, :token)
    end
  end
end
