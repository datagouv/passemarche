# frozen_string_literal: true

module Candidate
  class CompleteGroupingMember < ApplicationInteractor
    delegate :market_application, to: :context

    def call
      context.fail!(message: 'Application already completed') if market_application.completed?

      market_application.complete!
      market_application.grouping_member&.mark_completed!
    end
  end
end
