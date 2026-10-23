# frozen_string_literal: true

module Candidate
  module WizardRoutable
    extend ActiveSupport::Concern

    DEDICATED_STEP_ROUTES = %i[
      application_mode lot_selection_mode grouping_legal_type grouping_composition company_identification lot_selection
    ].freeze

    private

    def wizard_step_path(market_application, step)
      identifier = market_application.identifier
      return public_send(:"#{step}_candidate_market_application_path", identifier) if DEDICATED_STEP_ROUTES.include?(step)

      step_candidate_market_application_path(identifier, step)
    end

    def step_after_company_identification_path(market_application)
      wizard_step_path(market_application, market_application.step_after_company_identification)
    end

    def form_hub_path(market_application)
      return wizard_step_path(market_application, :company_identification) if market_application.company_identification_required?

      confirmed_grouping_dashboard_path(market_application)
    end

    def next_required_wizard_step_path(market_application)
      target, step = market_application.next_required_wizard_step
      return wizard_step_path(target, step) if target

      confirmed_grouping_dashboard_path(market_application) ||
        company_identification_candidate_market_application_path(market_application.identifier)
    end

    def grouping_member_dashboard_path(market_application)
      return nil unless market_application.grouping_member

      confirmed_grouping_dashboard_path(market_application)
    end

    def confirmed_grouping_dashboard_path(market_application)
      dashboard_application = market_application.confirmed_mandataire_grouping_application ||
                              market_application.confirmed_co_traitant_grouping_application
      return nil if dashboard_application.nil?

      grouping_dashboard_candidate_market_application_path(dashboard_application.identifier)
    end
  end
end
