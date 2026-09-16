# frozen_string_literal: true

module Candidate
  module WizardRoutable
    extend ActiveSupport::Concern

    private

    def wizard_step_path(market_application, step)
      case step
      when :application_mode
        application_mode_candidate_market_application_path(market_application.identifier)
      when :lot_selection_mode
        lot_selection_mode_candidate_market_application_path(market_application.identifier)
      when :grouping_legal_type
        grouping_legal_type_candidate_market_application_path(market_application.identifier)
      when :grouping_composition
        grouping_composition_candidate_market_application_path(market_application.identifier)
      when :company_identification
        company_identification_candidate_market_application_path(market_application.identifier)
      end
    end

    def next_required_wizard_step_path(market_application)
      target, step = market_application.next_required_wizard_step
      return wizard_step_path(target, step) if target

      mandataire_dashboard_path(market_application) ||
        company_identification_candidate_market_application_path(market_application.identifier)
    end

    def mandataire_dashboard_path(market_application)
      grouping_application = market_application.groupement_counterpart || market_application
      grouping = grouping_application.mandataire_grouping
      return nil if grouping.nil? || !grouping.composition_confirmed?

      grouping_dashboard_candidate_market_application_path(grouping_application.identifier)
    end
  end
end
