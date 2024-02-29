require 'rails_helper'

RSpec.describe ::AuthenticationServices::Helpers::RefreshTokenHelpers do
  describe '#generate_from' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:id) { SecureRandom.urlsafe_base64(52) }

    it 'returns a string that is creates based on input parameters' do
      expect(described_class.generate_from(user_id:, device:, id:)).to eq("#{user_id}.#{device}.#{id}")
    end
  end

  describe '#select_from_paload' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:id) { SecureRandom.urlsafe_base64(52) }

    it 'depends on generate_from method' do
      payload = { 'aud' => user_id,
                  'device' => device,
                  'jti' => id }

      expect(described_class.select_from_paload(payload)).to eq(described_class.generate_from(user_id:, device:, id:))
    end
  end
end
