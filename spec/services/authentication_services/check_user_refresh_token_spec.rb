require 'rails_helper'

RSpec.describe ::AuthenticationServices::CheckUserRefreshToken do
  describe 'success result' do
    context 'when only one refresh token exists' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }

      let!(:issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
      end

      let(:refresh_token) { described_class.call(device:, user_id:, refresh_token: issued_token) }

      it 'returns a refresh token' do
        expect(refresh_token.success?).to be true
        expect(refresh_token.result).to be_a String
        expect(refresh_token.result.length).to eq 70
      end
    end

    context 'when there are a sequence refresh tokens' do
      before do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
      end

      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }

      let(:third_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
      end

      let(:token_service) { described_class.call(device:, user_id:, refresh_token: third_issued_token) }

      it 'returns a refresh token' do
        expect(token_service.success?).to be true
        expect(token_service.result).to be_a String
        expect(token_service.result.length).to eq 70
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

    let!(:issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
    end

    let(:token_service) { described_class.call(device:, user_id:, refresh_token: issued_token) }

    it 'is not success' do
      expect(token_service.success?).to be false
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
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }

    let(:token_service) { described_class.call(device:, user_id:, refresh_token: 'fake-token') }

    it 'is not success' do
      expect(token_service.success?).to be false
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

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'Reuse detection' do
    context 'when last token is not sing_in' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }

      let!(:first_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
      end

      let(:token_service) { described_class.call(device:, user_id:, refresh_token: first_issued_token) }

      let(:current_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
      end

      it 'is not success' do
        # second_issued_token
        current_token
        expect(token_service.success?).to be false
        expect(token_service.result).to be_nil
      end

      it 'returns user readable error' do
        # second_issued_token
        current_token
        expect(token_service.user_readable_errors.full_messages)
          .to eq(['Authentication invalid credentials'])
      end

      it 'returns "Detected Reuse detection" exceptions' do
        # second_issued_token
        current_token
        expect(token_service.exceptions.full_messages).to eq(['Detected Reuse detection'])
      end
    end

    context 'when last token is sing_in' do
      let(:user_id) { create(:user).id }
      let(:device) { 'device' }
      let(:expire_at) { 1.hour.from_now }

      let!(:first_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
      end

      let(:token_service) { described_class.call(device:, user_id:, refresh_token: first_issued_token) }

      let(:current_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, action: 'sing_in', expire_at:).result
      end

      it 'is not success' do
        # second_issued_token
        current_token
        expect(token_service.success?).to be false
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

  describe 'when old refresh token is used' do
    before do
      first_issued_token
      second_issued_token
      third_issued_token
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }

    let(:first_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
    end

    let(:second_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
    end

    let(:third_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result
    end

    let(:token_service) { described_class.call(device:, user_id:, refresh_token: first_issued_token) }

    it 'is not success' do
      expect(token_service.success?).to be false
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
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
