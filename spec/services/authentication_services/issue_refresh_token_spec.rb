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
      expect(token_service.result).to be_a String
    end

    it 'returns a string where length' do
      expect(token_service.result.length).to eq 70
    end
  end

  describe 'DB required records' do
    context 'when required records are created' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:token_service) { described_class.call(user_id:, expire_at:, device:) }

      it 'creates UserRefreshToken record to find user_id by a token' do
        expect { token_service }.to change(UserRefreshToken, :count).from(0).to(1)
      end

      it 'creates RefreshToken record to find current and prev generated token' do
        expect { token_service }.to change(RefreshToken, :count).from(0).to(1)
      end

      it 'creates records where some attributes the same' do
        token_service
        only = [:created_at, :token, :user_id, :device]

        expect(UserRefreshToken.first.as_json(only:)).to eq(RefreshToken.first.as_json(only:))
      end
    end

    context 'when creating UserRefreshToken' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:token) { described_class.call(user_id:, device:, expire_at:).result }

      it 'saves a token as a digest' do
        token_digest = Digest::SHA256.hexdigest(token)

        expect(UserRefreshToken.find_by(token: token_digest)).not_to be_nil
      end

      it 'creates UserRefreshToken record to find user_id by a token' do
        token_digest = Digest::SHA256.hexdigest(token)
        user_refresh_token = UserRefreshToken.find_by(token: token_digest)

        attrs = user_refresh_token.as_json(only: [:user_id, :device])

        expect(attrs.symbolize_keys).to eq({ user_id:,
                                             device: })
      end
    end

    context 'when creating RefreshToken events' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:token) { described_class.call(user_id:, device:, expire_at:).result }

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
