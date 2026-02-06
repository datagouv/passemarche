# frozen_string_literal: true

class AuthorizationError < ApplicationError
  attr_reader :action, :resource

  def initialize(message, action: nil, resource: nil, context: {})
    @action = action
    @resource = resource
    super(message, context: context.merge(action:, resource:).compact)
  end
end
