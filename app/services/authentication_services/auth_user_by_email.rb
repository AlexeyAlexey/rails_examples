module AuthenticationServices
  class AuthUserByEmail
    prepend ::ApplicationService

    def initialize(email:, password:)
      @email = email
      @password = password
    end

    def call
      user_email = UserEmail.eager_load(:user).find_by(email:)

      @user = if user_email&.validated?
                user_email.user
              else
                user_readable_errors.add(:not_validated_email, 'was not validated')
                nil
              end

      return nil if @user.blank?

      if @user.authenticate(password)
        @user
      else
        user_readable_errors.add :authentication, 'invalid credentials'
        nil
      end
    end

    private

    attr_reader :email, :password
  end
end
