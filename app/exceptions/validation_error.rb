# frozen_string_literal: true

class ValidationError < ApplicationError
  attr_reader :errors

  def initialize(message, errors: [], context: {})
    @errors = errors
    super(message, context: context.merge(errors:))
  end
end
