# frozen_string_literal: true

class CreatePublicMarket < ApplicationInteractor
  delegate :editor, :params, to: :context

  def call
    context.fail!(errors: { editor: ['Editor not found'] }) unless editor

    market = editor.public_markets.build(market_params)

    if market.save
      context.public_market = market
    else
      context.fail!(errors: errors_from(market))
    end
  end

  private

  def market_params
    params.slice(:name, :lot_name, :deadline, :siret, :market_type_codes, :provider_user_id)
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
