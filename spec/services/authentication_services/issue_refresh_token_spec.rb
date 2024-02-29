require 'rails_helper'

RSpec.describe ::AuthenticationServices::IssueRefreshToken do
  before do
    ::PartitionServices::CreateRefreshToken.call(from: DateTime.now.utc,
                                                 to: DateTime.now.utc + 1.day,
                                                 interval: '1 DAY')
  end

  after do
    ::DBTest::DropTablePartitions.drop('refresh_tokens')
  end

  describe 'return result' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:token_service) { described_class.call(user_id:, device:, expire_at:) }

    it 'returns a refresh token' do
      expect(token_service.result.user_token).to be_a String
      expect(token_service.result.token).to be_a String
    end

    it 'returns a string where length' do
      expect(token_service.result.user_token.length).to be > 70
      expect(token_service.result.token.length).to be > 70
    end
  end

  describe 'DB required records' do
    context 'when required records are created' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:token_service) { described_class.call(user_id:, expire_at:, device:) }

      it 'creates RefreshToken record to find current and prev generated token' do
        expect { token_service }.to change(RefreshToken, :count).from(0).to(1)
      end
    end

    context 'when creating RefreshToken events' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:token) { described_class.call(user_id:, device:, expire_at:).result.token }

      it 'saves a token as a digest' do
        token_digest = Digest::SHA256.hexdigest(token)

        refresh_token = RefreshToken.where(device:, user_id:).order(created_at: :desc).first
        expect(refresh_token.token).to eq(token_digest)
      end

      it 'sets expire_at' do
        token
        refresh_token = RefreshToken.where(user_id:).order(created_at: :desc).first

        expect(refresh_token.expire_at.to_fs(:db)).to eq(expire_at.to_fs(:db))
      end
    end
  end
end
