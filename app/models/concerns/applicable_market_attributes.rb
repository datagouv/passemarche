# frozen_string_literal: true

module ApplicableMarketAttributes
  extend ActiveSupport::Concern

  def api_names_to_fetch
    applicable_market_attributes.filter_map(&:api_name).uniq
  end

  def selected_lot_types
    declared_lot_types.compact.uniq
  end

  def multi_type_selected_lots?
    selected_lot_types.size > 1
  end

  def applicable_market_type_codes
    lot_types = declared_lot_types
    return public_market.effective_market_type_codes if lot_types.empty? || lot_types.any?(&:nil?)

    lot_codes = lot_types.map(&:code).uniq
    public_market.defense_industry? ? lot_codes + ['defense'] : lot_codes
  end

  def applicable_market_attributes
    type_codes = applicable_market_type_codes
    market_attributes_with_types.select do |market_attribute|
      attribute_codes = market_attribute.market_types.map(&:code)
      attribute_codes.empty? || attribute_codes.intersect?(type_codes)
    end
  end

  def applicable_market_attribute_ids
    applicable_market_attributes.map(&:id)
  end

  def applicable_market_attribute_responses
    applicable_ids = applicable_market_attribute_ids
    market_attribute_responses.select { |response| applicable_ids.include?(response.market_attribute_id) }
  end

  def update_declared_lots!(lot_ids)
    transaction do
      self.lot_ids = lot_ids
      purge_inapplicable_data!
    end
  end

  def replace_lots_from_platform!(lot_ids)
    previous_type_codes = lots.any? ? applicable_market_type_codes : nil

    transaction do
      update_declared_lots!(lot_ids)
      assign_platform_lock(previous_type_codes)
      save!(validate: false)
    end
  end

  def unlock_platform_lots!
    self.lots_locked = false
    self.lots_changed_by_platform_at = nil
    save!(validate: false)
  end

  def purge_inapplicable_data!
    market_attribute_responses.where.not(market_attribute_id: applicable_market_attribute_ids).destroy_all
    market_attribute_responses.reset

    applicable_api_fetch_status = api_fetch_status.slice(*api_names_to_fetch)
    return if applicable_api_fetch_status == api_fetch_status

    self.api_fetch_status = applicable_api_fetch_status
    save!(validate: false)
  end

  private

  def assign_platform_lock(previous_type_codes)
    self.lots_locked = true
    self.application_mode = :solo if application_mode.nil?
    self.lots_changed_by_platform_at = Time.current if new_lot_types_since?(previous_type_codes)
  end

  def new_lot_types_since?(previous_type_codes)
    return false if previous_type_codes.nil?

    (applicable_market_type_codes - previous_type_codes).any?
  end

  def declared_lot_types
    declared_lots.includes(:market_type, :platform_market_type).map(&:effective_market_type)
  end

  def market_attributes_with_types
    public_market.market_attributes.includes(:market_types).to_a
  end
end
