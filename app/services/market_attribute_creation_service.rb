# frozen_string_literal: true

class MarketAttributeCreationService < ApplicationServiceObject
  def initialize(params:)
    super()
    @params = params
  end

  def perform
    validate_params
    return if failure?

    @result = build_market_attribute
    assign_position
    save_and_assign_market_types
  end

  private

  def validate_params
    add_error(:market_types, :blank) if market_type_ids.blank?
    add_error(:buyer_name, :blank) if @params[:buyer_name].blank?
    validate_api_params
  end

  def validate_api_params
    return unless @params[:source] == 'api'

    add_error(:api_name, :blank) if @params[:api_name].blank?
    add_error(:api_key, :blank) if @params[:api_key].blank?
  end

  def save_and_assign_market_types
    if @result.save
      @result.market_type_ids = market_type_ids
    else
      @result.errors.each { |error| add_error(error.attribute, error.message) }
    end
  end

  def build_market_attribute
    MarketAttribute.new(
      key: generate_key,
      input_type: @params[:input_type],
      mandatory: @params[:mandatory] || false,
      category_key: @params[:category_key],
      subcategory_key: @params[:subcategory_key],
      subcategory_id: resolve_subcategory_id,
      api_name: @params[:source] == 'api' ? @params[:api_name] : nil,
      api_key: @params[:source] == 'api' ? @params[:api_key] : nil,
      buyer_name: @params[:buyer_name],
      candidate_name: @params[:candidate_name],
      buyer_description: @params[:buyer_description],
      candidate_description: @params[:candidate_description]
    )
  end

  def generate_key
    @params[:buyer_name].parameterize(separator: '_')
  end

  def resolve_subcategory_id
    Subcategory.find_by(
      key: @params[:subcategory_key],
      category: Category.find_by(key: @params[:category_key])
    )&.id
  end

  def assign_position
    last_position = MarketAttribute
      .where(subcategory_key: @params[:subcategory_key])
      .active
      .maximum(:position) || 0
    @result.position = last_position + 1
  end

  def market_type_ids
    @params[:market_type_ids]&.reject(&:blank?)
  end
end
