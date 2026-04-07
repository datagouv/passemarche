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
    lots_attributes = (params[:lots].presence || []).each_with_index.map { |lot, i| { name: lot[:name], position: i + 1 } }
    params.slice(:name, :deadline, :siret, :market_type_codes, :provider_user_id).merge(lots_attributes:)
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
