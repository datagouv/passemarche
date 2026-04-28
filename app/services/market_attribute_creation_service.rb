# frozen_string_literal: true

class MarketAttributeCreationService
  attr_reader :result, :errors

  def initialize(params:)
    @params = params
    @errors = {}
  end

  def perform
    @result = build_market_attribute

    ActiveRecord::Base.transaction do
      validate_params
      raise ActiveRecord::Rollback if failure?

      assign_position
      save_and_assign_market_types
      raise ActiveRecord::Rollback if failure?
    end
  end

  def success?
    @errors.empty?
  end

  def failure?
    !success?
  end

  private

  def add_error(key, message)
    @errors[key] = message
  end

  def validate_params
    add_error(:market_types, I18n.t('errors.messages.blank')) if market_type_ids.blank?
    add_error(:buyer_name, I18n.t('errors.messages.blank')) if @params[:buyer_name].blank?
    add_error(:candidate_name, I18n.t('errors.messages.blank')) if @params[:candidate_name].blank?
    validate_api_params
  end

  def validate_api_params
    return unless @params[:configuration_mode] == 'api'

    add_error(:api_name, I18n.t('errors.messages.blank')) if @params[:api_name].blank?
    add_error(:api_key, I18n.t('errors.messages.blank')) if @params[:api_key].blank?
  end

  def save_and_assign_market_types
    if @result.save
      @result.market_type_ids = market_type_ids
    else
      @result.errors.each { |error| add_error(error.attribute, error.message) }
    end
  end

  def build_market_attribute
    attribute = MarketAttribute.new(base_attributes.merge(api_attributes))
    attribute.configuration_mode = @params[:configuration_mode]
    attribute
  end

  def base_attributes
    {
      key: generate_key,
      input_type: @params[:input_type],
      mandatory: @params[:mandatory] || false,
      category_key: subcategory&.category&.key,
      subcategory_key: subcategory&.key,
      subcategory_id: @params[:subcategory_id],
      buyer_name: @params[:buyer_name],
      candidate_name: @params[:candidate_name],
      buyer_description: @params[:buyer_description],
      candidate_description: @params[:candidate_description]
    }
  end

  def api_attributes
    return {} unless api_mode?

    { api_name: @params[:api_name], api_key: @params[:api_key] }
  end

  def generate_key
    return nil if @params[:buyer_name].blank?

    base_key = @params[:buyer_name].parameterize(separator: '_')
    return base_key unless MarketAttribute.exists?(key: base_key)

    counter = 1
    counter += 1 while MarketAttribute.exists?(key: "#{base_key}_#{counter}")
    "#{base_key}_#{counter}"
  end

  def subcategory
    return @subcategory if defined?(@subcategory)

    @subcategory = Subcategory.includes(:category).find_by(id: @params[:subcategory_id])
  end

  def assign_position
    last_position = MarketAttribute
      .where(subcategory_key: subcategory&.key)
      .active
      .maximum(:position) || 0
    @result.position = last_position + 1
  end

  def market_type_ids
    @params[:market_type_ids]&.reject(&:blank?)
  end

  def api_mode?
    @params[:configuration_mode] == 'api'
  end
end
