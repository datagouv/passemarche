# frozen_string_literal: true

class CreatePublicMarket < ApplicationInteractor
  delegate :editor, :params, to: :context

  def call
    validate_input!

    market = editor.public_markets.build(market_params)

    if market.save
      context.public_market = market
      FetchPublicMarketBuyerNameJob.perform_later(market.id)
    else
      context.fail!(errors: errors_from(market))
    end
  end

  private

  def validate_input!
    context.fail!(errors: { editor: ['Editor not found'] }) unless editor
    context.fail!(errors: { lots: invalid_lot_type_errors }) if invalid_lot_type_errors.any?
  end

  def market_params
    params.slice(:name, :deadline, :siret, :market_type_codes, :provider_user_id, :lot_limit)
      .merge(lots_attributes: lots_params, lot_types_locked: lot_types_transmitted?)
  end

  def lots
    params[:lots].presence || []
  end

  def lots_params
    lots.each_with_index.map { |lot, i| build_lot(lot, i) }
  end

  def build_lot(lot, index)
    { name: lot[:name], position: index + 1, cpv_code: lot[:cpv_code],
      platform_market_type: market_type_for_lot(lot[:lot_type_code]) }
  end

  def market_type_for_lot(lot_type_code)
    market_types_by_code[lot_type_code.presence || default_market_type_code]
  end

  def lot_types_transmitted?
    lots.any? && lots.all? { |lot| lot[:lot_type_code].present? }
  end

  def invalid_lot_type_errors
    @invalid_lot_type_errors ||= lots.each_with_index.filter_map do |lot, index|
      code = lot[:lot_type_code]
      next if code.blank? || MarketType::LOT_TYPE_CODES.include?(code)

      I18n.t('api.errors.invalid_lot_type_code',
        position: index + 1, code:, accepted_codes: MarketType::LOT_TYPE_CODES.join(', '))
    end
  end

  def default_market_type_code
    params[:market_type_codes]&.first
  end

  def market_types_by_code
    @market_types_by_code ||= MarketType
      .where(code: lots.filter_map { |lot| lot[:lot_type_code].presence } << default_market_type_code)
      .index_by(&:code)
  end

  def errors_from(record)
    record.errors.each_with_object({}) do |error, hash|
      (hash[error.attribute] ||= []) << error.message
    end
  end
end
