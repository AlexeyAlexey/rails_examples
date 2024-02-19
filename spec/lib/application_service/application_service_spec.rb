require 'spec_helper'

require_relative '../../factories/lib/appliation_service/test_application_service'

describe ::ApplicationService do
  describe '#call' do
    it 'returns the service object' do
      service = ::ApplicationService::TestApplicationService

      expect(service.call(2)).to be_a(::ApplicationService::TestApplicationService)
    end

    it 'raises an exception if the method is not defined in the command' do
      missed_call_method =
        Class.new do
          prepend ::ApplicationService
          # def call
          # method was not defined
          # end
        end

      expect do
        missed_call_method.call
      end.to raise_error(::ApplicationService::NotImplementedError)
    end
  end

  describe 'input arguments' do
    it 'receives keyword arguments' do
      service =
        Class.new do
          prepend ::ApplicationService

          def initialize(first:, second:)
            @first = first
            @second = second
          end

          def call
            "#{first} #{second}"
          end

          private

          attr_reader :first, :second
        end

      expect(service.call(first: 1, second: 2).result).to eq('1 2')
    end

    it 'receives positional arguments' do
      service =
        Class.new do
          prepend ::ApplicationService

          def initialize(first, second)
            @first = first
            @second = second
          end

          def call
            "#{first} #{second}"
          end

          private

          attr_reader :first, :second
        end

      expect(service.call(1, 2).result).to eq('1 2')
    end
  end

  describe '#success?' do
    context 'with no any errors' do
      let(:service) { ::ApplicationService::TestApplicationService.call(2) }

      it 'is true' do
        expect(service.success?).to be true
      end

      it 'when exceptions is empty' do
        expect(service.exceptions).to be_empty
      end

      it 'when user_readable_errors is empty' do
        expect(service.user_readable_errors).to be_empty
      end
    end

    context 'when user_readable_errors presents' do
      let(:service) do
        Class.new do
          prepend ::ApplicationService
          def call
            user_readable_errors.add(:base, 'failure')
          end
        end.call
      end

      it 'is false' do
        expect(service.success?).to be false
      end

      it 'when exceptions is empty' do
        expect(service.exceptions).to be_empty
      end

      it 'when user_readable_errors is not empty' do
        expect(service.user_readable_errors).not_to be_empty
      end
    end

    context 'when exceptions presents' do
      let(:service) do
        Class.new do
          prepend ::ApplicationService
          def call
            exceptions.add(:exceptions, 'exceptions')
          end
        end.call
      end

      it 'is false' do
        expect(service.success?).to be false
      end

      it 'when exceptions is not empty' do
        expect(service.exceptions).not_to be_empty
      end

      it 'when user_readable_errors is empty' do
        expect(service.user_readable_errors).to be_empty
      end
    end
  end

  describe '#result' do
    let(:service) { ::ApplicationService::TestApplicationService.call(2) }

    it 'returns the result of service execution' do
      expect(service.result).to eq(4)
    end
  end

  describe '#failure?' do
    context 'when success? is true' do
      let(:service) { ::ApplicationService::TestApplicationService.call(2) }

      it 'is when success? is true' do
        expect(service.success?).to be true
      end

      it 'is false' do
        expect(service.failure?).to be false
      end
    end

    context 'when success? is false' do
      let(:service) do
        Class.new do
          prepend ::ApplicationService
          def call
            user_readable_errors.add(:base, 'exceptions')
          end
        end.call
      end

      it 'is when success? is false' do
        expect(service.success?).to be false
      end

      it 'is true' do
        expect(service.failure?).to be true
      end
    end
  end

  describe '#user_readable_errors' do
    it 'returns an ApplicationService::Errors' do
      service = ::ApplicationService::TestApplicationService.call(2)

      expect(service.user_readable_errors).to be_a(::ApplicationService::Errors)
    end
  end

  describe '#exceptions' do
    it 'returns an ApplicationService::Errors' do
      service = ::ApplicationService::TestApplicationService.call(2)

      expect(service.exceptions).to be_a(::ApplicationService::Errors)
    end
  end
end
