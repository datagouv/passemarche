# frozen_string_literal: true

class MarketApplicationCreationService < ApplicationService
  def initialize(public_market:, siret:)
    @public_market = public_market
    @siret = siret
  end

  def call
    create_market_application
  end

  private

  attr_reader :public_market, :siret

  def create_market_application
    MarketApplication.create!(
      public_market: public_market,
      siret: siret
    )
  end
end
