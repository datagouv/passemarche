# frozen_string_literal: true

module Candidate
  module WizardRoutable
    extend ActiveSupport::Concern

    private

    def wizard_step_path(market_application, step)
      case step
      when :application_mode
        application_mode_candidate_market_application_path(market_application.identifier)
      when :grouping_legal_type
        grouping_legal_type_candidate_market_application_path(market_application.identifier)
      when :grouping_composition
        grouping_composition_candidate_market_application_path(market_application.identifier)
      end
    end

    def next_required_wizard_step_path(market_application)
      target, step = market_application.next_required_wizard_step
      return company_identification_candidate_market_application_path(market_application.identifier) unless target

      wizard_step_path(target, step)
    end
  end
end
