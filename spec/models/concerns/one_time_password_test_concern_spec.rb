require 'rails_helper'

class OneTimePasswordTestConcern
  include OneTimePassword

  attr_accessor :otp_secret_key, :validated_otp, :otp_tail

  def save
    false
  end
end

RSpec.describe OneTimePasswordTestConcern do
  it_behaves_like 'one time password'
end
