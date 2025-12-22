# frozen_string_literal: true

class MarketApplicationPresenter
  include SidemenuHelper
  include MarketAttributeGrouping

  INITIAL_WIZARD_STEPS = %i[company_identification api_data_recovery_status market_information].freeze
  FINAL_WIZARD_STEP = :summary
  MARKET_INFO_PARENT_CATEGORY = 'identite_entreprise'
  ATTESTATION_MOTIFS_EXCLUSION_STEP = :attestation_motifs_exclusion

  def initialize(market_application)
    @market_application = market_application
  end

  def fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def category_keys_with_attestation_motifs_exclusion
    category_keys = @market_application.public_market.market_attributes
      .order(:id)
      .pluck(:category_key)
      .compact
      .uniq

    inject_attestation_motifs_exclusion_step(category_keys)
  end

  def parent_category_for(subcategory_key)
    return nil if subcategory_key.blank?
    return MARKET_INFO_PARENT_CATEGORY if subcategory_key.to_s == 'market_information'

    all_market_attributes
      .where(subcategory_key: subcategory_key.to_s)
      .pluck(:category_key)
      .compact
      .first
  end

  def subcategories_for_category(category_key)
    return [] if category_key.blank?

    subcategories = []
    subcategories << 'market_information' if category_key == MARKET_INFO_PARENT_CATEGORY

    category_subcategories = all_market_attributes
      .where(category_key: category_key.to_s)
      .order(:position)
      .pluck(:subcategory_key)
      .compact
      .uniq

    subcategories + category_subcategories
  end

  def field_by_key(key)
    MarketAttribute.find_by(key: key.to_s)
  end

  def market_attributes_for_subcategory(category_key, subcategory_key)
    return [] if category_key.blank? || subcategory_key.blank?

    all_market_attributes
      .where(category_key:, subcategory_key:)
      .order(:position)
  end

  def market_attribute_response_for(market_attribute)
    @market_application.market_attribute_responses.find { |response| response.market_attribute_id == market_attribute.id } ||
      @market_application.market_attribute_responses.build(
        market_attribute:,
        type: MarketAttributeResponse.type_from_input_type(market_attribute.input_type)
      )
  end

  def responses_for_subcategory(category_key, subcategory_key)
    return [] if category_key.blank? || subcategory_key.blank?

    market_attributes = market_attributes_for_subcategory(category_key, subcategory_key)
    market_attributes.map { |attr| market_attribute_response_for(attr) }
  end

  def responses_for_category(category_key)
    return [] if category_key.blank?

    all_market_attributes
      .where(category_key:)
      .order(:position)
      .map { |attr| market_attribute_response_for(attr) }
  end

  def responses_grouped_by_subcategory(category_key)
    responses_for_category(category_key).group_by { |r| r.market_attribute.subcategory_key }
  end

  def stepper_steps
    steps = category_keys.map(&:to_sym)
    steps = inject_attestation_motifs_exclusion_step(steps)
    steps + [FINAL_WIZARD_STEP]
  end

  def wizard_steps
    all_steps = (INITIAL_WIZARD_STEPS + subcategory_keys.map(&:to_sym) + [FINAL_WIZARD_STEP]).uniq
    inject_attestation_motifs_exclusion_step(all_steps)
  end

  def optional_market_attributes?
    @market_application.public_market.market_attributes.exists?(mandatory: false)
  end

  def missing_mandatory_motifs_exclusion?
    mandatory_motifs_exclusion_attributes.any? do |attr|
      response = market_attribute_response_for(attr)
      !response_has_data?(response)
    end
  end

  private

  def mandatory_motifs_exclusion_attributes
    @market_application.public_market.market_attributes
      .where(mandatory: true)
      .where('category_key LIKE ?', 'motifs_exclusion%')
  end

  def response_has_data?(response)
    return false if response.nil? || response.new_record?

    has_documents = response.respond_to?(:documents) && response.documents.attached?
    has_value = response.value.present?

    has_documents || has_value
  end

  def all_market_attributes
    @market_application.public_market.market_attributes.order(:position)
  end

  def organize_fields_by_category_and_subcategory(market_attributes)
    category_keys = @market_application.public_market.market_attributes
      .order(:position)
      .pluck(:category_key)
      .compact
      .uniq

    category_keys.each_with_object({}) do |category_key, result|
      category_attrs = market_attributes.select { |attr| attr.category_key == category_key }
      result[category_key] = group_by_subcategory(category_attrs) if category_attrs.any?
    end
  end

  def category_keys
    @category_keys ||= all_market_attributes
      .order(:position)
      .pluck(:category_key)
      .compact
      .uniq
  end

  def subcategory_keys
    @subcategory_keys ||= all_market_attributes
      .order(:position)
      .pluck(:subcategory_key)
      .compact
      .uniq
  end

  def inject_attestation_motifs_exclusion_step(steps)
    first_exclusion_index = steps.find_index { |s| s.to_s.start_with?('motifs_exclusion') }
    return steps unless first_exclusion_index

    steps.insert(first_exclusion_index, ATTESTATION_MOTIFS_EXCLUSION_STEP)
    steps
  end
end
