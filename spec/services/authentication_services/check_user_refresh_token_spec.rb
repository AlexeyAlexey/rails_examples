require 'rails_helper'

RSpec.describe ::AuthenticationServices::CheckUserRefreshToken do
  before do
    ::PartitionServices::CreateRefreshToken.call(from: DateTime.now.utc,
                                                 to: DateTime.now.utc + 1.day,
                                                 interval: '1 DAY')
  end

  after do
    ::DBTest::DropTablePartitions.drop('refresh_tokens')
  end

  describe 'success result' do
    context 'when only one refresh token exists' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:lifetime) { 40000 }

      let!(:issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.token
      end

      let(:refresh_token) { described_class.call(device:, user_id:, refresh_token: issued_token, lifetime:) }

      it 'returns a refresh token' do
        expect(refresh_token).to be_success
        expect(refresh_token.result).to be_a String
        expect(refresh_token.result.length).to be > 70
      end
    end

    context 'when there are a sequence refresh tokens' do
      before do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      end

      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:lifetime) { 40000 }

      let(:third_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.token
      end

      let(:token_service) { described_class.call(device:, user_id:, refresh_token: third_issued_token, lifetime:) }

      it 'returns a refresh token' do
        expect(token_service).to be_success
        expect(token_service.result).to be_a String
        expect(token_service.result.length).to be > 70
      end
    end
  end

  describe 'when token is illegal' do
    before do
      allow_any_instance_of(RefreshToken).to receive(:illegal?).and_return(true)
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:lifetime) { 40000 }

    let!(:issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.token
    end

    let(:token_service) { described_class.call(device:, user_id:, refresh_token: issued_token, lifetime:) }

    it 'is not success' do
      expect(token_service).to be_failure
      expect(token_service.result).to be_nil
    end

    it 'returns user readable error' do
      expect(token_service.user_readable_errors.full_messages)
        .to eq(['Authentication invalid credentials'])
    end

    it 'does not return exceptions' do
      expect(token_service.exceptions.full_messages).to eq([])
    end
  end

  describe 'when a refresh token is expired' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:lifetime) { 40000 }

    let(:refresh_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at: DateTime.now - 1.hour).result.token
    end

    let(:token_service) { described_class.call(device:, user_id:, refresh_token:, lifetime:) }

    it 'is not success' do
      expect(token_service).to be_failure
      expect(token_service.result).to be_nil
    end

    it 'returns user readable error' do
      expect(token_service.user_readable_errors.full_messages)
        .to eq(['Authentication invalid credentials'])
    end

    it 'does not return exceptions' do
      expect(token_service.exceptions.full_messages).to eq([])
    end
  end

  describe 'when token cannot be found' do
    before do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:lifetime) { 40000 }

    let(:token_service) { described_class.call(device:, user_id:, refresh_token: 'fake-token', lifetime:) }

    it 'is not success' do
      expect(token_service).to be_failure
      expect(token_service.result).to be_nil
    end

    it 'returns user readable error' do
      expect(token_service.user_readable_errors.full_messages)
        .to eq(['Authentication invalid credentials'])
    end

    it 'does not return exceptions' do
      expect(token_service.exceptions.full_messages).to eq([])
    end
  end

  describe 'Reuse detection' do
    context 'when last token is not sing_in' do
      before do
        first_issued_token
        second_issued_token
      end

      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:lifetime) { 40000 }

      let!(:first_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.token
      end

      let(:second_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      end

      let(:token_service) { described_class.call(device:, user_id:, refresh_token: first_issued_token, lifetime:) }

      let(:current_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      end

      it 'is not success' do
        current_token
        expect(token_service).to be_failure
        expect(token_service.result).to be_nil
      end

      it 'returns user readable error' do
        current_token
        expect(token_service.user_readable_errors.full_messages)
          .to eq(['Authentication invalid credentials'])
      end

      it 'returns "Detected Reuse detection" exceptions' do
        current_token
        expect(token_service.exceptions.full_messages).to eq(['Detected Reuse detection'])
      end
    end

    context 'when last token is sing_in' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }
      let(:lifetime) { 40000 }

      let!(:first_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.token
      end

      let(:token_service) { described_class.call(device:, user_id:, refresh_token: first_issued_token, lifetime:) }

      let(:current_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, action: 'sing_in', expire_at:)
      end

      it 'is not success' do
        # second_issued_token
        current_token
        expect(token_service).to be_failure
        expect(token_service.result).to be_nil
      end

      it 'returns user readable error' do
        # second_issued_token
        current_token
        expect(token_service.user_readable_errors.full_messages)
          .to eq(['Authentication invalid credentials'])
      end

      it 'does not return "Detected Reuse detection" exceptions' do
        # second_issued_token
        current_token
        expect(token_service.exceptions.full_messages).to eq([])
      end
    end
  end

  describe 'when expired refresh token is used' do
    before do
      first_issued_token
      second_issued_token
      third_issued_token
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:lifetime) { 40000 }

    let(:first_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:,
                                                       device:,
                                                       expire_at: DateTime.now.utc - 10.seconds).result.token
    end

    let(:second_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
    end

    let(:third_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
    end

    let(:token_service) { described_class.call(device:, user_id:, refresh_token: first_issued_token, lifetime:) }

    it 'is not success' do
      expect(token_service).to be_failure
      expect(token_service.result).to be_nil
    end

    it 'returns user readable error' do
      expect(token_service.user_readable_errors.full_messages)
        .to eq(['Authentication invalid credentials'])
    end

    it 'does not return exceptions' do
      expect(token_service.exceptions.full_messages).to eq([])
    end
  end
end
