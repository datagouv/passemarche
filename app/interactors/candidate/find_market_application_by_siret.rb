# frozen_string_literal: true

module Candidate
  class FindMarketApplicationBySiret < ApplicationInteractor
    delegate :siret, to: :context

    def call
      application = MarketApplication.find_by(siret:)

      if application
        context.market_application = application
      else
        context.fail!(errors: { siret: [I18n.t('candidate.request_magic_link.no_application_found')] })
      end
    end
  end
end
