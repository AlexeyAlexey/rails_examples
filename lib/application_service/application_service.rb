# frozen_string_literal: true

require_relative 'errors'
require_relative 'utils'

# Copied from
# https://github.com/nebulab/simple_command/blob/master/lib/simple_command/utils.rb
module ApplicationService
  attr_reader :result

  module ClassMethods
    def call(*params)
      new(*params).call
    end
  end

  def self.prepended(base)
    base.extend ClassMethods
  end

  def call
    raise NotImplementedError unless defined?(super)

    @result = super

    self
  end

  def success?
    !failure?
  end
  alias successful? success?

  def failure?
    exceptions.any? || user_readable_errors.any?
  end

  def user_readable_errors
    @user_readable_errors ||= Errors.new
  end

  def exceptions
    @exceptions ||= Errors.new
  end
end
