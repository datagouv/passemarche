# frozen_string_literal: true

class PdfGenerationError < ApplicationError
  attr_reader :template_name, :market_application_id

  def initialize(message, template_name: nil, market_application_id: nil, context: {})
    @template_name = template_name
    @market_application_id = market_application_id
    super(message, context: context.merge(template_name:, market_application_id:).compact)
  end
end
