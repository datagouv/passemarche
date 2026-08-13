# frozen_string_literal: true

module Candidate
  module ApplicationModeGuard
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_application_mode_choice
    end

    private

    def redirect_to_application_mode_choice
      return unless @market_application&.application_mode_choice_required?

      redirect_to application_mode_candidate_market_application_path(@market_application.identifier)
    end
  end
end
