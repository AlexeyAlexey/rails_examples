require 'rails_helper'

RSpec.describe ::AuthenticationServices::FindUserByRefreshToken do
  describe 'when token can be found' do
    before do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }

    let(:refresh_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
    end

    it 'is success' do
      found_user = described_class.call(refresh_token:)

      expect(found_user.success?).to be true
    end

    it 'returns required attrs' do
      found_user = described_class.call(refresh_token:).result

      expect(found_user.to_h.keys.sort).to eq([:user_id, :device, :token].sort)
    end

    it 'returns object with required attrs' do
      found_user = described_class.call(refresh_token:).result

      expect(found_user.user_id).to eq(user_id)
      expect(found_user.device).to eq(device)
      expect(found_user.token).to eq(refresh_token)
    end
  end

  describe 'when token cannot be found' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }

    let(:refresh_token) do
      'fake token'
    end

    let(:not_found) { described_class.call(refresh_token:) }

    it 'is failure' do
      expect(not_found.failure?).to be true
    end

    it 'returns nil' do
      expect(not_found.result).to be_nil
    end

    it 'adds exceptions' do
      expect(not_found.exceptions.full_messages).to eq(['Not_found refresh token'])
    end
  end
end
