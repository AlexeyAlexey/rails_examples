class ApplicationController < ActionController::API
  before_action :authorize_request

  rescue_from ::AuthenticationExceptions::Unauthorized do |exception|
    render json: { errors: { base: [exception.message] } }, status: :unauthorized
  end

  private

  attr_reader :current_user, :current_device

  def authorize_request
    type, access_token = request.headers['Authorization']&.split(' ')

    raise ::AuthenticationExceptions::Unauthorized unless type == 'Bearer'

    access_token = ::AuthenticationServices::ParseAccessToken.call(access_token:)

    raise ::AuthenticationExceptions::Unauthorized if access_token.failure?

    begin
      @current_user = User.find(access_token.result.user_id)
      @current_device = access_token.result.device
    rescue ActiveRecord::RecordNotFound
      raise ::AuthenticationExceptions::Unauthorized, 'Invalid token'
    end
  end
end
