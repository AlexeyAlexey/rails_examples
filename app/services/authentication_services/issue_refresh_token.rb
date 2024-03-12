module AuthenticationServices
  class IssueRefreshToken
    prepend ::ApplicationService

    def initialize(user_id:, device:, expire_at:, action: RefreshToken::ACTIONS['issued'])
      @user_id = user_id
      @device = device
      @action = action
      @expire_at = expire_at
    end

    def call
      res = ::AuthenticationServices::GenerateRefreshToken.call(user_id:, device:, expire_at:)

      if res.failure?
        exceptions.add_multiple_errors res.exceptions

        return nil
      end

      RefreshToken.create(user_id:,
                          token: Digest::SHA256.hexdigest(res.result.token),
                          device:,
                          action:,
                          expire_at:,
                          created_at: DateTime.now.utc)

      response_object.new(user_token: res.result.user_token, token: res.result.token)
    end

    private

    attr_reader :user_id, :device, :action, :expire_at

    def response_object
      @response_object ||= Struct.new(:user_token, :token)
    end
  end
end
