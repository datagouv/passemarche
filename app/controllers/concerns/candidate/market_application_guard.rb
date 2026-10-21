# frozen_string_literal: true

module Candidate
  module MarketApplicationGuard
    extend ActiveSupport::Concern
    include Candidate::WizardRoutable

    included do
      before_action :check_application_editable
    end

    private

    def check_application_editable
      case @market_application&.lock_reason
      when :deadline_passed
        redirect_to deadline_passed_candidate_market_application_path(@market_application.identifier)
      when :grouping_submitted
        redirect_to grouping_submitted_redirect_path
      when :completed
        redirect_to locked_application_redirect_path
      end
    end

    def grouping_submitted_redirect_path
      return locked_candidate_market_application_path(@market_application.identifier) if @market_application.co_traitant_of_grouping?

      locked_application_redirect_path
    end

    def locked_application_redirect_path
      grouping_member_dashboard_path(@market_application) || candidate_sync_status_path(@market_application.identifier)
    end
  end
end
