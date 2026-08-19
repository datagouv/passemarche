# frozen_string_literal: true

module Candidate
  class CreateApplicationsForMode < ApplicationInteractor
    delegate :market_application, :application_mode, to: :context

    def call
      context.public_market = market_application.public_market
      context.siret = market_application.siret

      ActiveRecord::Base.transaction do
        dispatch_mode
        raise ActiveRecord::Rollback if context.failure?
      end
    end

    private

    delegate :public_market, :siret, to: :context

    def dispatch_mode
      case application_mode.to_s
      when 'solo' then set_solo
      when 'groupement' then set_groupement
      when 'mixte' then set_mixte
      else context.fail!(errors: { application_mode: [I18n.t('candidate.validations.application_mode_invalid')] })
      end
    end

    def set_solo
      return context.fail!(errors: market_application.errors.to_hash) unless market_application.update(application_mode: :solo)

      context.market_application = market_application
    end

    def set_groupement
      return context.fail!(errors: market_application.errors.to_hash) unless market_application.update(application_mode: :groupement)

      context.market_application = market_application
      create_grouping(market_application)
    end

    def set_mixte
      return context.fail!(errors: market_application.errors.to_hash) unless market_application.update(application_mode: :solo)

      create_groupement_counterpart
    end

    def create_groupement_counterpart
      result = CreateMarketApplication.call(public_market:, siret:, application_mode: :groupement)
      return context.fail!(errors: result.errors) if result.failure?

      groupement_application = result.market_application
      return fail_already_mandataire if owned_by_another_user?(groupement_application)

      link_solo_user(groupement_application)
      context.market_application = groupement_application
      create_grouping(groupement_application)
    end

    def owned_by_another_user?(groupement_application)
      market_application.user && groupement_application.user &&
        groupement_application.user_id != market_application.user_id
    end

    def link_solo_user(groupement_application)
      groupement_application.update!(user: market_application.user) if market_application.user
    end

    def create_grouping(mandataire_application)
      grouping = Grouping.create(public_market:)
      return context.fail!(errors: { grouping: grouping.errors.full_messages }) unless grouping.persisted?

      create_mandataire_member(grouping, mandataire_application)
    end

    def create_mandataire_member(grouping, mandataire_application)
      member = grouping.grouping_members.create(mandataire_member_attributes(mandataire_application))

      return fail_already_mandataire if uniqueness_error?(member)

      context.fail!(errors: { grouping_member: member.errors.full_messages }) unless member.persisted?
    rescue ActiveRecord::RecordNotUnique
      fail_already_mandataire
    end

    def mandataire_member_attributes(mandataire_application)
      { role: :mandataire, siret:, email: mandataire_application.user&.email, market_application: mandataire_application }
    end

    def uniqueness_error?(member)
      member.errors.of_kind?(:siret, :taken) || member.errors.of_kind?(:grouping_id, :taken)
    end

    def fail_already_mandataire
      context.fail!(errors: { application_mode: [I18n.t('candidate.validations.already_mandataire')] })
    end
  end
end
