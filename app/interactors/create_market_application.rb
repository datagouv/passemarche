# frozen_string_literal: true

class CreateMarketApplication < ApplicationInteractor
  delegate :public_market, :siret, :provider_user_id, to: :context

  def call
    current_application = find_application

    return create_new_application unless current_application
    return handle_recandidature(current_application) if current_application.completed?

    context.market_application = current_application
  end

  private

  def application_mode
    context.application_mode || :solo
  end

  def find_application
    MarketApplication.matching_mode(application_mode).find_by(public_market:, siret:)
  end

  def handle_recandidature(application)
    return context.market_application = application unless public_market.open?

    reset_existing_application(application)
  end

  def reset_existing_application(application)
    ResetMarketApplication.call!(market_application: application)
    context.market_application = application
  end

  def create_new_application
    application = MarketApplication.new(public_market:, siret:, provider_user_id:, application_mode:)

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
