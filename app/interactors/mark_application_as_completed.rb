# frozen_string_literal: true

class MarkApplicationAsCompleted < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Application already completed') if market_application.completed?

    market_application.complete!
    context.completed_at = market_application.completed_at
  end
end
