require 'rails_helper'

RSpec.describe ::AuthenticationServices::IssueAccessToken do
  describe 'required attributes' do
    let(:user_id) { create(:user).id }
    let(:expire_at) { 1.hour.from_now }
    let(:access_token) { described_class.call(user_id:, expire_at:) }

    it 'includes header and body and signature' do
      expect(access_token).to be_success
      expect(access_token.result).to be_a String
      expect(access_token.result.split('.').size).to eq(3)
    end

    it 'sets required attributes' do
      payload = Base64.decode64(access_token.result.split('.')[1])

      expect(JSON.parse(payload)).to include({ 'sub' => be_kind_of(String),
                                               'exp' => be_kind_of(Integer),
                                               'jti' => be_kind_of(String),
                                               'aud' => user_id,
                                               'iat' => be_kind_of(Integer) })
    end
  end

  describe 'optional attributes' do
    let(:user_id) { create(:user).id }
    let(:expire_at) { 1.hour.from_now }
    let(:opt_attrs) { { device: 'device' } }

    it 'sets device' do
      device = 'device'
      access_token = described_class.call(user_id:, opt_attrs:, expire_at:)
      payload = Base64.decode64(access_token.result.split('.')[1])

      expect(JSON.parse(payload)).to include({ 'device' => device })
    end
  end

  describe 'reserved attributes' do
    let(:user_id) { create(:user).id }
    let(:expire_at) { 1.hour.from_now }
    let(:opt_attrs) { { sub: '1', exp: 1, jti: '1', aud: '1', 'iat' => 1 } }

    it 'sets device' do
      access_token = described_class.call(user_id:, opt_attrs:, expire_at:)
      payload = Base64.decode64(access_token.result.split('.')[1])
      payload = JSON.parse(payload)

      expect(payload['aud']).not_to eq('1')
      expect(payload['exp']).not_to eq(1)
      expect(payload['iat']).not_to eq(1)
      expect(payload['jti']).not_to eq('1')
      expect(payload['sub']).not_to eq('1')
    end
  end
end
