require 'rails_helper'

RSpec.describe ::AuthenticationServices::ParseAccessToken do
  describe 'required attributes' do
    let(:user_id) { create(:user).id }
    let(:expire_at) { 1.hour.from_now }
    let(:access_token) { AuthenticationServices::IssueAccessToken.call(user_id:, expire_at:).result }

    it 'returns user_id' do
      res = described_class.call(access_token:)

      expect(res).to be_success
      expect(res.result.user_id).to eq user_id
    end
  end

  describe 'optional attributes' do
    let(:user_id) { create(:user).id }
    let(:expire_at) { 1.hour.from_now }
    let(:opt_attrs) { { device: 'device' } }

    it 'returns device attr value' do
      device = 'device'
      access_token = AuthenticationServices::IssueAccessToken.call(user_id:, opt_attrs:, expire_at:).result
      res = described_class.call(access_token:)

      expect(res).to be_success
      expect(res.result.device).to eq device
    end
  end
end
