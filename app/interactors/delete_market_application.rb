# frozen_string_literal: true

class DeleteMarketApplication < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail!(message: 'Impossible de supprimer une candidature transmise') if market_application.completed?

    user = market_application.user
    siret = market_application.siret

    market_application.destroy!

    context.next_application = user && MarketApplication.for_user(user).for_siret(siret).first
  end
end
