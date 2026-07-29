# frozen_string_literal: true

module Candidate
  class CreateApplicationsForMode < ApplicationInteractor
    delegate :public_market, :siret, :application_mode, to: :context

    def call
      validate_application_mode
      return if context.failure?

      ActiveRecord::Base.transaction do
        dispatch_mode
        raise ActiveRecord::Rollback if context.failure?
      end
    end

    private

    delegate :public_market, :siret, to: :context

    def dispatch_mode
      case application_mode.to_s
      when 'solo' then create_solo
      when 'groupement' then create_groupement
      when 'mixte' then create_mixte
      else context.fail!(errors: { application_mode: [I18n.t('candidate.validations.application_mode_invalid')] })
      end
    end

    def validate_application_mode
      result = ValidateApplicationMode.call(public_market:, siret:, application_mode:)
      context.fail!(errors: result.errors) if result.failure?
    end

    def create_solo
      result = CreateMarketApplication.call(public_market:, siret:, application_mode: :solo)
      return context.fail!(errors: result.errors) if result.failure?

      context.market_application = result.market_application
      context.solo_market_application = result.market_application
    end

    def create_groupement
      result = CreateMarketApplication.call(public_market:, siret:, application_mode: :groupement)
      return context.fail!(errors: result.errors) if result.failure?

      context.market_application = result.market_application
      context.groupement_market_application = result.market_application
      create_grouping(result.market_application)
    end

    def create_mixte
      create_solo
      return if context.failure?

      create_groupement
      return if context.failure?

      context.market_application = context.groupement_market_application
    end

    def create_grouping(mandataire_application)
      grouping = Grouping.create(public_market:, mandataire_market_application: mandataire_application)
      return fail_already_mandataire if grouping.errors[:mandataire_siret].present?
      return context.fail!(errors: { grouping: grouping.errors.full_messages }) unless grouping.persisted?

      create_mandataire_member(grouping, mandataire_application)
    rescue ActiveRecord::RecordNotUnique
      fail_already_mandataire
    end

    def create_mandataire_member(grouping, mandataire_application)
      member = grouping.grouping_members.create(
        role: :mandataire,
        siret:,
        email: mandataire_application.user&.email,
        market_application: mandataire_application
      )

      return fail_already_mandataire if member.errors[:grouping_id].present?

      context.fail!(errors: { grouping_member: member.errors.full_messages }) unless member.persisted?
    rescue ActiveRecord::RecordNotUnique
      fail_already_mandataire
    end

    def fail_already_mandataire
      context.fail!(errors: { application_mode: [I18n.t('candidate.validations.already_mandataire')] })
    end
  end
end
