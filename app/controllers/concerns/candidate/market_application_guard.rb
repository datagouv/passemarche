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
      return unless @market_application&.locked?

      if @market_application.public_market.open?
        redirect_to locked_application_redirect_path
      else
        redirect_to deadline_passed_candidate_market_application_path(@market_application.identifier)
      end
    end

    def locked_application_redirect_path
      grouping_member_dashboard_path(@market_application) || candidate_sync_status_path(@market_application.identifier)
    end
  end
end
