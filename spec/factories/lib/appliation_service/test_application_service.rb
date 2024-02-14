# frozen_string_literal: true

module ApplicationService
  class TestApplicationService
    prepend ::ApplicationService

    def initialize(input)
      @input = input
    end

    def call
      @input * 2
    end
  end
end
