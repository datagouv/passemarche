# frozen_string_literal: true

class ApiDataMappingError < ApplicationError
  attr_reader :api_name, :key, :original_error

  def initialize(message, api_name: nil, key: nil, original_error: nil, context: {})
    @api_name = api_name
    @key = key
    @original_error = original_error
    super(message, context: context.merge(api_name:, key:, original_error_class: original_error&.class&.name).compact)
  end
end
