require 'rails_helper'

RSpec.shared_examples 'one time password' do
  describe 'methods' do
    let(:object) { described_class.new }

    it do
      expect(object).to respond_to(:generate_one_time_password).with(0).arguments
      expect(object).to respond_to(:authenticate_otp).with(2).arguments
      expect(object).to respond_to(:validated_otp?).with(0).arguments
      expect(object).to respond_to(:valid_otp?).with(2).arguments
    end
  end

  describe 'constants' do
    let(:object) { described_class.new }

    it do
      expect(described_class::DEFAULT_OTP_INTERVAL).to eq(60)
      expect(described_class::OTP_LENGTH).to eq(5)
    end
  end

  describe '#generate_one_time_password' do
    context 'when saved successfully' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(true)
      end

      let(:object) { described_class.new }

      it 'calls save method' do
        expect(object).to receive(:save)

        object.generate_one_time_password
      end

      # If there is a requirement to show less than a generated code
      it 'saves a tail from a generated code' do
        expect(object).to receive(:otp_tail=).with(an_instance_of(String))

        object.generate_one_time_password
      end

      it 'returns string where length is 5' do
        res = object.generate_one_time_password

        expect(res).to be_a String
        expect(res.length).to eq 5
      end

      it 'sets otp_tail attribute' do
        object.generate_one_time_password

        expect(object.otp_tail.length).to eq(1)
      end
    end

    context 'when failed to save' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(false)
      end

      let(:object) { described_class.new }

      it 'calls save method' do
        expect(object).to receive(:save)

        object.generate_one_time_password
      end

      it 'saves a tail from a generated code' do
        expect(object).to receive(:otp_tail=).with(an_instance_of(String))

        object.generate_one_time_password
      end

      it 'returns nil' do
        expect(object.generate_one_time_password).to eq nil
      end
    end
  end

  describe '#authenticate_otp' do
    context 'when successfully saved' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(true)
      end

      let(:object) { described_class.new }

      it 'calls save method' do
        code = object.generate_one_time_password

        expect(object).to receive(:save)

        object.authenticate_otp(code)
      end

      it 'sets validated_otp to true' do
        code = object.generate_one_time_password

        expect { object.authenticate_otp(code) }.to change(object, :validated_otp).from(false).to(true)
      end

      it 'returns self' do
        code = object.generate_one_time_password

        expect(object.authenticate_otp(code)).to be_a described_class
      end
    end

    context 'when failed to save' do
      let(:object) { described_class.new }

      it 'calls save method' do
        allow_any_instance_of(described_class).to receive(:save).and_return(true)
        code = object.generate_one_time_password

        allow_any_instance_of(described_class).to receive(:save).and_return(false)

        expect(object).to receive(:save)

        object.authenticate_otp(code)
      end

      it 'sets validated_otp to false' do
        allow_any_instance_of(described_class).to receive(:save).and_return(true)

        code = object.generate_one_time_password

        allow_any_instance_of(described_class).to receive(:save).and_return(false)

        object.authenticate_otp(code)

        expect(object.validated_otp).to eq false
      end
    end

    context 'when code is not valid' do
      before do
        allow_any_instance_of(described_class).to receive(:save).and_return(true)
      end

      let(:object) { described_class.new }

      it 'calls save method' do
        object.generate_one_time_password
        code = '11111'

        expect(object).to receive(:save)

        object.authenticate_otp(code)
      end

      it 'sets validated_otp to true' do
        object.generate_one_time_password

        object.authenticate_otp('11111')

        expect(object.validated_otp).to eq false
      end

      it 'returns self' do
        object.generate_one_time_password

        expect(object.authenticate_otp('11111')).to be_a described_class
      end
    end

    context 'when code format is not valid' do
      let(:object) { described_class.new }

      it 'does not call save method' do
        expect(object).not_to receive(:save)

        object.authenticate_otp('1')
      end

      it 'sets validated_otp to false' do
        object.validated_otp = true

        expect { object.authenticate_otp('1') }.to change(object, :validated_otp).from(true).to(false)
      end

      it 'returns self' do
        object.generate_one_time_password

        expect(object.authenticate_otp('1')).to be_a described_class
      end
    end
  end
end
