# frozen_string_literal: true

class CreateMarketApplication < ApplicationInteractor
  delegate :public_market, :siret, :provider_user_id, to: :context

  def call
    application = MarketApplication.new(public_market:, siret:, provider_user_id:)

    if application.save
      context.market_application = application
    else
      context.fail!(errors: errors_from(application))
    end
  end

  private

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
