require 'rails_helper'

RSpec.describe ::AuthenticationServices::RotateRefreshToken do
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
      let(:lifetime) { 4000 }

      let!(:issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.user_token
      end

      let(:token_service) { described_class.call(refresh_token: issued_token, lifetime:) }

      it 'returns a refresh token' do
        expect(token_service).to be_success
        expect(token_service.result).to be_a String
        expect(token_service.result.length).to be > 70
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
      let(:lifetime) { 4000 }

      let(:third_issued_token) do
        ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.user_token
      end

      let(:token_service) { described_class.call(refresh_token: third_issued_token, lifetime:) }

      it 'returns a refresh token' do
        expect(token_service).to be_success
        expect(token_service.result).to be_a String
        expect(token_service.result.length).to be > 70
      end
    end
  end

  describe 'when token is illegal' do
    before do
      # Using `any_instance` to stub a method (failure?)
      # that has been defined on a prepended module (ApplicationService) is not supported
      obj = Struct.new(:exceptions, :result, :failure?).new({}, nil, true)
      allow(::AuthenticationServices::CheckUserRefreshToken).to receive(:call).and_return(obj)
    end

    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:lifetime) { 4000 }

    let!(:issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.user_token
    end

    let(:token_service) { described_class.call(refresh_token: issued_token, lifetime:) }

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
    let(:lifetime) { 4000 }

    let(:token_service) { described_class.call(refresh_token: 'faketoken', lifetime:) }

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

  describe 'when detected "Reuse detection"' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { 1.hour.from_now }
    let(:lifetime) { 4000 }

    let!(:first_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:).result.user_token
    end

    let(:token_service) { described_class.call(refresh_token: first_issued_token, lifetime:) }

    it 'is not success' do
      # second_issued_token
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      expect(token_service).to be_failure
      expect(token_service.result).to be_nil
    end

    it 'returns user readable error' do
      # second_issued_token
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      expect(token_service.user_readable_errors.full_messages)
        .to eq(['Authentication invalid credentials'])
    end

    it 'does not return exceptions' do
      # second_issued_token
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
      expect(token_service.exceptions.full_messages).to eq(['Detected Reuse detection'])
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
    let(:lifetime) { 4000 }

    let(:first_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:,
                                                       device:,
                                                       expire_at: DateTime.now.utc - 10.seconds).result.user_token
    end

    let(:second_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
    end

    let(:third_issued_token) do
      ::AuthenticationServices::IssueRefreshToken.call(user_id:, device:, expire_at:)
    end

    let(:token_service) { described_class.call(refresh_token: first_issued_token, lifetime:) }

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
