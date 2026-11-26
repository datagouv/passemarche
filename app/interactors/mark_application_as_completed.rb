# frozen_string_literal: true

class MarkApplicationAsCompleted < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Candidature déjà complétée') if market_application.completed?

    market_application.lots_changed_by_platform_at = nil
    market_application.complete!
    context.completed_at = market_application.completed_at
  end
end
