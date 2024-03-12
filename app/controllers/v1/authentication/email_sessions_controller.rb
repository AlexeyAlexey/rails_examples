module V1
  module Authentication
    class EmailSessionsController < ApplicationController
      skip_before_action :authorize_request, only: [:create]

      def create
        user = ::AuthenticationServices::AuthUserByEmail.call(email: params[:email],
                                                              password: params[:password])
        if user.success?
          user_id = user.result.id
          device = 'device'

          access_token = ::AuthenticationServices::IssueAccessToken \
                         .call(user_id:,
                               expire_at: Time.now.utc + ::AuthCredentials::AccessToken.lifetime.seconds,
                               opt_attrs: { device: })

          refresh_token =
            if access_token.success?
              ::AuthenticationServices::IssueRefreshToken \
                .call(user_id:,
                      device:,
                      expire_at: Time.now.utc + AuthCredentials::RefreshToken.lifetime.seconds)
            end

          if access_token.success? && refresh_token&.success?
            response.headers['Authorization'] = "Bearer #{access_token.result}"

            render json: { refresh_token: refresh_token.result.user_token }
          else
            errors = access_token.user_readable_errors.merge(refresh_token&.user_readable_errors || {})

            render json: { errors: }, status: :unauthorized
          end
        else
          render json: { errors: user.user_readable_errors }, status: :unauthorized
        end
      end

      def destroy
        res = ::AuthenticationServices::InvalidateRefreshTokens.call(user_id: current_user.id,
                                                                     refresh_token: 'token',
                                                                     device: current_device,
                                                                     action: RefreshToken::ACTIONS['sign_out'],
                                                                     reason: 'sign_out')

        if res.failure?
          # exception should be processed
          Rails.logger.error "[#{self.class.name}] A Refresh Token cannot be invalidated" \
            "#{res.exceptions.full_messages.join(' ')}"
        end

        render json: { message: 'You were signed out' }, status: :ok
      end
    end
  end
end
