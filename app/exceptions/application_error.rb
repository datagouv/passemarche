# frozen_string_literal: true

class ApplicationError < StandardError
  attr_reader :context

  def initialize(message = nil, context: {})
    @context = context
    super(message)
  end

  def to_h
    {
      error_class: self.class.name,
      message:,
      context:
    }
  end
end
