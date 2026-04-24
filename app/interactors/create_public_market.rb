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
    params.slice(:name, :deadline, :siret, :market_type_codes, :provider_user_id, :lot_limit)
      .merge(lots_attributes: lots_params)
  end

  def lots_params
    (params[:lots].presence || []).each_with_index.map { |lot, i| build_lot(lot, i) }
  end

  def build_lot(lot, index)
    { name: lot[:name], position: index + 1, cpv_code: lot[:cpv_code] }
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
