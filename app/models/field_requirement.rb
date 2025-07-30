# frozen_string_literal: true

class FieldRequirement
  include FieldConstants
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :market_type, :string
  attribute :defense_industry, :boolean, default: false

  validates :market_type, presence: true
  validates :market_type, inclusion: { in: MARKET_TYPES }

  def initialize(market_type:, defense_industry: false)
    super
    @config = load_requirements_config
  end

  def required_field_keys
    keys = market_type_required_keys + defense_required_keys
    keys.uniq
  end

  def optional_field_keys
    keys = market_type_optional_keys + defense_optional_keys
    keys.uniq
  end

  def defense_optional_field_keys
    defense_optional_keys
  end

  def field_required?(field_key)
    required_field_keys.include?(field_key.to_s)
  end

  def field_optional?(field_key)
    optional_field_keys.include?(field_key.to_s)
  end

  def field_available?(field_key)
    field_required?(field_key) || field_optional?(field_key)
  end

  def field_defense_only?(field_key)
    defense_optional_keys.include?(field_key.to_s) || defense_required_keys.include?(field_key.to_s)
  end

  private

  def market_type_required_keys
    @config.dig(:market_types, market_type.to_sym, :required) || []
  end

  def market_type_optional_keys
    @config.dig(:market_types, market_type.to_sym, :optional) || []
  end

  def defense_required_keys
    return [] unless defense_industry

    @config.dig(:defense, :required) || []
  end

  def defense_optional_keys
    return [] unless defense_industry

    @config.dig(:defense, :optional) || []
  end

  def load_requirements_config
    Rails.application.config_for('form_fields/field_requirements')
  end
end
