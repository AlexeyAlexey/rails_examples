module AuthenticationServices
  class ParseAccessToken
    prepend ::ApplicationService

    def initialize(access_token:)
      @access_token = access_token
    end

    def call
      begin
        token, *_rest = JWT.decode access_token,
                                   ::AuthCredentials::AccessToken.private_key,
                                   true,
                                   { algorithm: ::AuthCredentials::AccessToken.algorithm,
                                     sub: 'rails_examples',
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
      rescue JWT::DecodeError => e
        exceptions.add :jwt, "Decode Error #{e.message}"
      rescue JWT::VerificationError
        exceptions.add :jwt, 'Verification Error'
      rescue JWT::ExpiredSignature
        exceptions.add :jwt, 'Expired Signature'
      rescue ArgumentError
        exceptions.add :refresh_token, 'Invalid Format'
      rescue StandardError => e
        exceptions.add :error, e.message
      end

      if exceptions.present?
        user_readable_errors.add :authentication, 'invalid credentials'

        return nil
      end

      filtered_payload = token.reject do |key, _value|
        IssueAccessToken::RESERVED_ATTRS.include?(key.to_sym)
      end

      OpenStruct.new(filtered_payload.merge(user_id: token['aud']))
    end

    private

    attr_reader :access_token
  end
end
