# frozen_string_literal: true

class LotSelectionPolicy
  include ActiveModel::Validations

  attr_reader :market_application, :lot_ids

  LOT_ID_FORMAT = /\A\d+\z/

  validate :only_lot_identifiers
  validate :at_least_one_lot_selected
  validate :lots_belong_to_market
  validate :lots_within_groupement_scope
  validate :lot_limit_respected

  def initialize(market_application, lot_ids)
    @market_application = market_application
    @raw_lot_ids = Array(lot_ids).reject { |value| value == '' }
    @lot_ids = @raw_lot_ids.select { |value| lot_identifier?(value) }.map(&:to_i).uniq
  end

  private

  def lot_identifier?(value)
    (value.is_a?(String) || value.is_a?(Integer)) && LOT_ID_FORMAT.match?(value.to_s)
  end

  def only_lot_identifiers
    errors.add(:base, :invalid_lot_id) unless @raw_lot_ids.all? { |value| lot_identifier?(value) }
  end

  def at_least_one_lot_selected
    errors.add(:base, :no_lot_selected) if lot_ids.empty?
  end

  def lots_belong_to_market
    return if lot_ids.empty?

    market_lot_ids = market_application.public_market.lots.ids
    errors.add(:base, :lot_outside_market) unless lot_ids.all? { |id| market_lot_ids.include?(id) }
  end

  def lot_limit_respected
    return unless FeatureFlags::LotLimit.enabled?

    limit = market_application.public_market.lot_limit
    return unless limit

    errors.add(:base, :lot_limit_exceeded, limit:, count: lot_ids.size) if lot_ids.size > limit
  end

  def lots_within_groupement_scope
    return unless market_application.grouping_member&.co_traitant?

    allowed_ids = market_application.groupement_scope_lots.ids
    errors.add(:base, :lot_outside_groupement_scope) unless lot_ids.all? { |id| allowed_ids.include?(id) }
  end
end
