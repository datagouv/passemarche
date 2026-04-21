# frozen_string_literal: true

class CreateMarketApplication < ApplicationInteractor
  delegate :public_market, :siret, :provider_user_id, to: :context

  def call
    application = find_or_build_application

    if application.persisted? || application.save
      context.market_application = application
    else
      context.fail!(errors: errors_from(application))
    end
  end

  private

  def find_or_build_application
    MarketApplication.find_by(public_market:, siret:) ||
      MarketApplication.new(public_market:, siret:, provider_user_id:)
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
