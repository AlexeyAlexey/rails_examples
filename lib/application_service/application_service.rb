# frozen_string_literal: true

require_relative 'errors'
require_relative 'utils'

# Copied from
# https://github.com/nebulab/simple_command/blob/master/lib/simple_command/utils.rb

# https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
# Alternatively, if you do not need compatibility with Ruby 2.6 or prior and you don’t alter
# any arguments, you can use the new delegation syntax (...) that is introduced in Ruby 2.7.
module ApplicationService
  attr_reader :result

  module ClassMethods
    def call(...)
      new(...).call
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
