# frozen_string_literal: true

module Candidate
  class FindMarketApplicationBySiret < ApplicationInteractor
    delegate :siret, :email, :market_application_id, to: :context

    def call
      application = find_application

      unless application
        context.fail!(errors: { siret: [I18n.t('candidate.request_magic_link.no_application_found')] })
        return
      end

      context.market_application = application
      handle_reconnection(application)
    end

    private

    def handle_reconnection(application)
      existing_user = find_existing_siret_user(application)
      context.reconnection = existing_user.present?
      return unless context.reconnection

      validate_email_for_user(existing_user)
      context.user = existing_user
    end

    def find_existing_siret_user(application)
      return application.user if application.user_id.present?

      MarketApplication.where(siret:).where.not(user_id: nil).first&.user
    end

    def validate_email_for_user(existing_user)
      return if existing_user.email.casecmp(email).zero?

      context.fail!(errors: { email: [I18n.t('candidate.request_magic_link.email_mismatch')] })
    end

    def find_application
      MarketApplication.find_by(identifier: market_application_id, siret:)
    end
  end
end
