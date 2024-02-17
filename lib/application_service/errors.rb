# frozen_string_literal: true

module ApplicationService
  class NotImplementedError < ::StandardError; end

  class Errors < Hash
    def add(key, value, _opts = {})
      self[key] ||= []
      self[key] << value
    end

    def add_multiple_errors(errors_hash)
      errors_hash.each do |key, values|
        ::ApplicationService::Utils.array_wrap(values).each { |value| add key, value }
      end
    end

    def each
      each_key do |field|
        self[field].each { |message| yield field, message }
      end
    end

    def full_messages
      map { |attribute, message| full_message(attribute, message) }
    end

    private

    def full_message(attribute, message)
      return message if attribute == :base

      attr_name = attribute.to_s.tr('.', '_').capitalize

      "#{attr_name} #{message}"
    end
  end
end
