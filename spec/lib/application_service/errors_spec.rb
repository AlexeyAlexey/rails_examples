require 'spec_helper'

describe ::ApplicationService::Errors do
  describe '#add' do
    let(:errors) { described_class.new }

    it 'adds the error' do
      errors.add :some_error, 'some error description'

      expect(errors[:some_error]).to eq(['some error description'])
    end

    it 'adds the same error' do
      errors.add :some_error, 'some error description'
      errors.add :some_error, 'some error description'
      expect(errors[:some_error]).to eq(['some error description', 'some error description'])
    end
  end

  describe '#add_multiple_errors' do
    let(:errors) { described_class.new }

    it 'populates itself with the added errors' do
      errors_list = {
        some_error: ['some error description'],
        another_error: ['another error description']
      }

      errors.add_multiple_errors errors_list

      expect(errors).to eq(errors_list)
    end

    it 'copies errors from another SimpleCommand::Errors object' do
      command_errors = described_class.new
      command_errors.add :some_error, 'was not found'
      command_errors.add :some_error, 'happened again'

      errors.add_multiple_errors command_errors

      expect(errors[:some_error]).to eq(['was not found', 'happened again'])
    end

    it "ignores nil values" do
      errors.add_multiple_errors({ foo: nil })

      expect(errors[:foo]).to eq nil
    end
  end

  describe '#each' do
    let(:errors) { described_class.new }

    let(:errors_list) do
      {
        email: ['taken'],
        password: ['blank', 'too short']
      }
    end

    it 'yields each message for the same key independently' do
      errors.add_multiple_errors(errors_list)

      expect { |b| errors.each(&b) }.to yield_successive_args(
        [:email, 'taken'],
        [:password, 'blank'],
        [:password, 'too short']
      )
    end
  end

  describe '#full_messages' do
    let(:errors) { described_class.new }

    it 'returrns the full messages array' do
      errors.add :attr1, 'has an error'
      errors.add :attr2, 'has an error'
      errors.add :attr2, 'has two errors'

      expect(errors.full_messages).to eq ['Attr1 has an error',
                                          'Attr2 has an error',
                                          'Attr2 has two errors']
    end
  end
end
