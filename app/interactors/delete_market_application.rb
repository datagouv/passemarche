# frozen_string_literal: true

class DeleteMarketApplication < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    context.fail! if market_application.completed?
    context.fail! unless market_application.destroy

    context.next_application = next_application_for_user
  end

  private

  def next_application_for_user
    user = market_application.user
    return unless user

    MarketApplication.for_user(user).for_siret(market_application.siret).first
  end
end
