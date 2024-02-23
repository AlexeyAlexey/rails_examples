require 'rails_helper'

RSpec.describe RefreshToken, type: :model do
  describe '#legal?' do
    context 'when it is true' do
      let(:expire_at) { 1.hour.from_now }

      it 'is when expire_at more than current time' do
        expect(described_class.new(expire_at:, action: 'issued').legal?).to be true
      end

      it 'is when action in' do
        described_class::LEGAL_ACTIONS.each do |action|
          expect(described_class.new(expire_at:, action:).legal?).to be true
        end
      end
    end

    context 'when it is false' do
      it 'when expire_at less than current time' do
        expire_at = DateTime.now.utc - 1.hour

        expect(described_class.new(expire_at:, action: 'issued').legal?).to be false
      end

      it 'is when action is wrong' do
        expire_at = 1.hour.from_now

        expect(described_class.new(expire_at:, action: 'deleted').legal?).to be false
      end
    end
  end

  describe '#illegal?' do
    it 'is true when legal? is false' do
      refresh_token_object = described_class.new

      allow(refresh_token_object).to receive(:legal?).and_return false

      expect(refresh_token_object.illegal?).to be true
    end

    it 'is false when legal? is true' do
      refresh_token_object = described_class.new

      allow(refresh_token_object).to receive(:legal?).and_return true

      expect(refresh_token_object.illegal?).to be false
    end
  end
end
