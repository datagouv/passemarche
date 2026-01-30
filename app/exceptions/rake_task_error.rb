# frozen_string_literal: true

class RakeTaskError < ApplicationError
  attr_reader :exit_code

  def initialize(message, exit_code: 1, context: {})
    @exit_code = exit_code
    super(message, context: context.merge(exit_code:))
  end
end
