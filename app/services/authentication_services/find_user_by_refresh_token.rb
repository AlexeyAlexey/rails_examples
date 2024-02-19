module AuthenticationServices
  class FindUserByRefreshToken
    prepend ::ApplicationService

    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      res = UserRefreshToken.find_by(token: digest_refresh_token)

      return response_object.new(device: res.device, user_id: res.user_id, token: refresh_token) if res.present?

      exceptions.add :not_found, 'refresh token'

      nil
    end

    private

    attr_reader :refresh_token

    def digest_refresh_token
      @digest_refresh_token ||= Digest::SHA256.hexdigest(refresh_token)
    end

    def response_object
      @response_object ||= Struct.new(:device, :user_id, :token, keyword_init: true)
    end
  end
end
