# frozen_string_literal: true

class CreatePublicMarket < ApplicationInteractor
  delegate :editor, :params, to: :context

  def call
    context.fail!(errors: { editor: ['Editor not found'] }) unless editor

    market = editor.public_markets.build(market_params)

    if market.save
      context.public_market = market
      FetchPublicMarketBuyerNameJob.perform_later(market.id)
    else
      context.fail!(errors: errors_from(market))
    end
  end

  private

  def market_params
    params.slice(:name, :deadline, :siret, :market_type_codes, :provider_user_id, :lot_limit)
      .merge(lots_attributes: lots_params)
  end

  def lots_params
    (params[:lots].presence || []).each_with_index.map { |lot, i| build_lot(lot, i) }
  end

  def build_lot(lot, index)
    { name: lot[:name], position: index + 1, cpv_code: lot[:cpv_code],
      platform_market_type: market_type_for_lot(lot[:lot_type_code]) }
  end

  def market_type_for_lot(lot_type_code)
    code = lot_type_code.presence || params[:market_type_codes]&.first
    MarketType.find_by(code:)
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
