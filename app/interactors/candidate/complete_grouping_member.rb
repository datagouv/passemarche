# frozen_string_literal: true

module Candidate
  class CompleteGroupingMember < ApplicationInteractor
    delegate :market_application, to: :context

    def call
      market_application.transaction do
        MarkApplicationAsCompleted.call!(context)
        market_application.grouping_member&.mark_completed!
      end
    end
  end
end
