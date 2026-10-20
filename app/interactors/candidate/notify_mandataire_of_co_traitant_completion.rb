# frozen_string_literal: true

module Candidate
  class NotifyMandataireOfCoTraitantCompletion < ApplicationInteractor
    delegate :market_application, to: :context

    def call
      grouping_member = market_application.grouping_member
      return unless grouping_member&.co_traitant?

      mandataire_application = grouping_member.grouping.mandataire_market_application
      mandataire_email = mandataire_application&.user&.email
      return log_missing_recipient(grouping_member) if mandataire_email.blank?

      GroupingMemberCompletionMailer
        .completed(grouping_member, mandataire_email, dashboard_url(mandataire_application))
        .deliver_later
    end

    private

    def dashboard_url(mandataire_application)
      Rails.application.routes.url_helpers.grouping_dashboard_candidate_market_application_url(
        mandataire_application.identifier
      )
    end

    def log_missing_recipient(grouping_member)
      Rails.logger.warn("No mandataire email to notify completion of grouping member #{grouping_member.id}")
    end
  end
end
