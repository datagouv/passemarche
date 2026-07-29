# frozen_string_literal: true

module Candidate
  class ValidateApplicationMode < ApplicationInteractor
    MODES = %w[solo groupement mixte].freeze
    MANDATAIRE_MODES = %w[groupement mixte].freeze

    delegate :public_market, :siret, :application_mode, to: :context

    def call
      return context.fail!(errors: { application_mode: [I18n.t('candidate.validations.application_mode_invalid')] }) unless valid_mode?

      return unless requires_mandataire_role?
      return unless already_mandataire?

      context.fail!(errors: { application_mode: [I18n.t('candidate.validations.already_mandataire')] })
    end

    private

    def valid_mode?
      application_mode.to_s.in?(MODES)
    end

    def requires_mandataire_role?
      application_mode.to_s.in?(MANDATAIRE_MODES)
    end

    def already_mandataire?
      Grouping
        .joins(:mandataire_market_application)
        .exists?(public_market:, market_applications: { siret: })
    end
  end
end
