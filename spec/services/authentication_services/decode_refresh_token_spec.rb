require 'rails_helper'

RSpec.describe ::AuthenticationServices::DecodeRefreshToken do
  describe 'success' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { ::AuthCredentials::RefreshToken.lifetime.seconds.from_now }

    it 'success? is true' do
      user_token = ::AuthenticationServices::GenerateRefreshToken.call(user_id:, device:, expire_at:).result.user_token

      expect(described_class.call(refresh_token: user_token)).to be_success
    end

    it 'returns a token' do
      gen_refresh_token = ::AuthenticationServices::GenerateRefreshToken.call(user_id:, device:, expire_at:).result

      user_token = gen_refresh_token.user_token

      res = described_class.call(refresh_token: user_token).result

      expect(res.token).to eq(gen_refresh_token.token)
      expect(res.user_id).to eq(user_id)
      expect(res.device).to eq(device)
    end
  end

  describe 'failed cases' do
    it 'is when a refresh token is not Base64 encoded string' do
      res = described_class.call(refresh_token: 'fake-token')

      expect(res).to be_failure
      expect(res.exceptions.full_messages).to eq(['Refresh_token Invalid Format'])
    end

    it 'is when it is not encrypted JWT token' do
      res = described_class.call(refresh_token: Base64.urlsafe_encode64('fake-token'))

      expect(res).to be_failure
      expect(res.exceptions.full_messages).to eq(["Jwt Decode Error"])
    end
  end
end
