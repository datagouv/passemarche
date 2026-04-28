# frozen_string_literal: true

class LotSelectionPolicy
  include ActiveModel::Validations

  attr_reader :market_application, :lot_ids

  validate :at_least_one_lot_selected
  validate :lot_limit_respected

  def initialize(market_application, lot_ids)
    @market_application = market_application
    @lot_ids = Array(lot_ids).map(&:to_i).reject(&:zero?)
  end

  private

  def at_least_one_lot_selected
    errors.add(:base, :no_lot_selected) if lot_ids.empty?
  end

  def lot_limit_respected
    limit = market_application.public_market.lot_limit
    return unless limit

    errors.add(:base, :lot_limit_exceeded, limit:, count: lot_ids.size) if lot_ids.size > limit
  end
end
