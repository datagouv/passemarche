# frozen_string_literal: true

class CreateMarketApplication < ApplicationInteractor
  delegate :public_market, :siret, :provider_user_id, to: :context

  def call
    current_application = MarketApplication.find_by(public_market:, siret:)

    return create_new_application unless current_application
    return handle_recandidature(current_application) if current_application.completed?

    context.market_application = current_application
  end

  private

  def handle_recandidature(application)
    return context.market_application = application unless public_market.open?

    reset_existing_application(application)
  end

  def reset_existing_application(application)
    result = ResetMarketApplication.call(market_application: application)

    if result.success?
      context.market_application = application
    else
      context.fail!(errors: { base: [result.message] })
    end
  end

  def create_new_application
    application = MarketApplication.new(public_market:, siret:, provider_user_id:)

    if application.save
      context.market_application = application
    else
      context.fail!(errors: errors_from(application))
    end
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
