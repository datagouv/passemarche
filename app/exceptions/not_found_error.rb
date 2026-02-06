# frozen_string_literal: true

class NotFoundError < ApplicationError
  attr_reader :resource_type, :identifier

  def initialize(message, resource_type: nil, identifier: nil, context: {})
    @resource_type = resource_type
    @identifier = identifier
    super(message, context: context.merge(resource_type:, identifier:).compact)
  end
end
