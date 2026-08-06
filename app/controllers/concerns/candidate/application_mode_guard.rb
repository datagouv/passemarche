# frozen_string_literal: true

module Candidate
  module ApplicationModeGuard
    extend ActiveSupport::Concern

    included do
      before_action :redirect_to_application_mode_choice
    end

    private

    def redirect_to_application_mode_choice
      return unless @market_application

      target, step = @market_application.next_required_wizard_step
      redirect_to_wizard_step(step, target) if target
    end

    def redirect_to_wizard_step(step, market_application = @market_application)
      redirect_to grouping_wizard_step_candidate_market_application_path(market_application.identifier, step)
    end
  end
end
