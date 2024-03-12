module V1
  module Authentication
    class EmailsController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

      skip_before_action :authorize_request
      before_action :find_user_email, only: [:validate]

      def create
        user = User.create(create_params)

        if user.errors.blank?
          user_email = user.user_emails.first
          ::MessageServices::Authentication::SendOtp.call(code: user_email.generate_one_time_password,
                                                          objct_id: user_email.id,
                                                          type: :email)

          render json: { success: 'Verification code was sent to your email' }
        else
          render json: { errors: user.errors.messages }, status: :unauthorized
        end
      end

      def validate
        if @user_email.authenticate_otp(validate_params[:code]).validated_otp?
          @user_email.update(validated: true)

          render json: { success: 'The email was validated' }, status: 200
        else
          render json: {}, status: :unauthorized
        end
      end

      private

      def create_params
        permited = params.require(:user).permit(:first_name,
                                                :password,
                                                :password_confirmation,
                                                user_emails_attributes: [:email])

        permited.slice(:first_name, :password, :password_confirmation)
                .merge({ user_emails_attributes: [permited[:user_emails_attributes].first] })
      end

      def validate_params
        @validate_params ||= params.require(:user).permit(:email, :code)
      end

      def find_user_email
        @user_email = UserEmail.find_by(email: validate_params[:email])

        @user_email || raise(ActiveRecord::RecordNotFound)
      end

      def record_not_found
        render json: { errors: { base: ['Not Found'] } }, status: 404
      end
    end
  end
end
