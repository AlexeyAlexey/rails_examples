module OneTimePassword
  extend ActiveSupport::Concern

  included do
    DEFAULT_OTP_INTERVAL = 60 # seconds
    OTP_LENGTH = 5
  end

  def valid_otp?(code, options = {})
    options[:interval] ||= DEFAULT_OTP_INTERVAL

    totp = ROTP::TOTP.new(self.otp_secret_key, options)

    result = totp.verify("#{code}#{self.otp_tail}", at: Time.now.utc)

    result.present?
  end

  def validated_otp?
    self.validated_otp
  end

  # (user = user.authenticate_otp(code)) && user.validated_otp?
  def authenticate_otp(code, options = {})
    if code&.length != OTP_LENGTH
      self.validated_otp = false

      return self
    end

    if valid_otp?(code, options)
      self.validated_otp = true

      regenerate_otp_secret_key
    end

    self.validated_otp = false unless self.save

    self
  end

  def random_otp_secret_key
    ROTP::Base32.random
  end

  def regenerate_otp_secret_key
    self.otp_secret_key = random_otp_secret_key
  end

  def generate_one_time_password(options = {})
    options[:interval] ||= DEFAULT_OTP_INTERVAL

    self.validated_otp = false

    regenerate_otp_secret_key

    totp = ROTP::TOTP.new(self.otp_secret_key, options)
    string = totp.at(Time.now.utc)

    self.otp_tail = string[OTP_LENGTH..string.length]

    self.save ? string[0..(OTP_LENGTH - 1)] : nil
  end
end
