# frozen_string_literal: true

module Candidate
  class FindMarketApplicationBySiret < ApplicationInteractor
    delegate :siret, :email, to: :context

    def call
      application = MarketApplication.find_by(siret:)

      unless application
        context.fail!(errors: { siret: [I18n.t('candidate.request_magic_link.no_application_found')] })
        return
      end

      context.market_application = application
      handle_reconnection(application)
    end

    private

    def handle_reconnection(application)
      context.reconnection = application.user_id.present?
      return unless context.reconnection

      validate_email_for_reconnection(application)
      context.user = application.user
    end

    def validate_email_for_reconnection(application)
      existing_email = application.user.email
      return if existing_email.casecmp(email).zero?

      context.fail!(errors: { email: [I18n.t('candidate.request_magic_link.email_mismatch')] })
    end
  end
end
