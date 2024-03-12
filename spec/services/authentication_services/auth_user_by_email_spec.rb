require 'rails_helper'

RSpec.describe ::AuthenticationServices::AuthUserByEmail do
  describe 'when success' do
    it 'is status' do
      create(:user_with_email)
      expect(described_class.call(email: 'user@mail.com', password: 'password')).to be_success
    end

    it 'is result' do
      user = create(:user_with_email)
      expect(described_class.call(email: 'user@mail.com', password: 'password').result.id).to eq(user.id)
    end
  end

  describe 'when password is wrong' do
    before do
      create(:user_with_email)
    end

    it 'is status' do
      expect(described_class.call(email: 'user@mail.com', password: 'wrongpassword')).to be_failure
    end

    it 'is result' do
      expect(described_class.call(email: 'user@mail.com', password: 'wrongpassword').result).to eq(nil)
    end
  end

  describe 'when an email is wrong' do
    before do
      create(:user_with_email)
    end

    it 'is status' do
      expect(described_class.call(email: 'wrongpassword@mail.com', password: 'password')).to be_failure
    end

    it 'is result' do
      expect(described_class.call(email: 'wrongpassword@mail.com', password: 'password').result).to eq(nil)
    end
  end

  describe 'when user uses an invalid email' do
    before do
      create(:user_with_invalid_email)
    end

    it 'is status' do
      expect(described_class.call(email: 'user@mail.com', password: 'password')).to be_failure
    end

    it 'is result' do
      expect(described_class.call(email: 'user@mail.com', password: 'password').result).to eq(nil)
    end
  end
end
