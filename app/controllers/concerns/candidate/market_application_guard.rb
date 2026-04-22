# frozen_string_literal: true

module Candidate
  module MarketApplicationGuard
    extend ActiveSupport::Concern

    included do
      before_action :check_application_not_completed
    end

    private

    def check_application_not_completed
      return unless @market_application&.completed?

      redirect_to candidate_sync_status_path(@market_application.identifier),
        alert: t('candidate.market_applications.market_application_completed_cannot_edit')
    end
  end
end
