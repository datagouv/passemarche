# frozen_string_literal: true

module Candidate
  module ApplicationModeGuard
    extend ActiveSupport::Concern
    include Candidate::WizardRoutable

    included do
      before_action :redirect_to_application_mode_choice
    end

    private

    def redirect_to_application_mode_choice
      return unless @market_application

      redirect_to next_required_wizard_step_path(@market_application) if @market_application.next_required_wizard_step
    end
  end
end
