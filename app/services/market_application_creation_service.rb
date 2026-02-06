# frozen_string_literal: true

class MarketApplicationCreationService < ApplicationServiceObject
  def initialize(public_market:, siret:, provider_user_id: nil)
    super()
    @public_market = public_market
    @siret = siret
    @provider_user_id = provider_user_id
  end

  def perform
    create_market_application
    self
  end

  private

  attr_reader :public_market, :siret, :provider_user_id

  def create_market_application
    application = MarketApplication.new(
      public_market:,
      siret:,
      provider_user_id:
    )

    if application.save
      @result = application
    else
      application.errors.each do |error|
        add_error(error.attribute, error.message)
      end
    end
  end
end
