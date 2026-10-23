# frozen_string_literal: true

module Candidate
  class CompleteGroupingMember < ApplicationInteractor
    delegate :market_application, to: :context

    def call
      context.already_transmitted = market_application.completed? && market_application.co_traitant_of_grouping?
      complete_application

      NotifyMandataireOfCoTraitantCompletion.call!(context)
    end

    private

    def complete_application
      validate_retransmitted_application if context.already_transmitted

      market_application.transaction do
        MarkApplicationAsCompleted.call!(context) unless context.already_transmitted
        market_application.grouping_member&.mark_completed!
      end
    end

    def validate_retransmitted_application
      return if market_application.valid?

      context.fail!(message: I18n.t('candidate.market_applications.completion_error'))
    end
  end
end
