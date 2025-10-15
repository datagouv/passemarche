# frozen_string_literal: true

class MapApiData < ApplicationInteractor
  def call
    return unless context.market_application

    validate_context
    return if context.failure?

    map_attributes_to_responses
  end

  private

  def validate_context
    return if context.bundled_data.present?

    context.fail!(error: 'Missing bundled_data')
  end

  def map_attributes_to_responses
    api_attributes.each do |market_attribute|
      create_or_update_response(market_attribute)
    end
  end

  def api_attributes
    context.market_application.public_market.market_attributes
      .where(api_name: context.api_name)
      .where.not(api_name: nil)
  end

  def create_or_update_response(market_attribute)
    response = find_or_initialize_response(market_attribute)
    value = extract_value_from_resource(market_attribute)

    response.text = value
    # Set source to auto unless it's already manual_after_api_failure
    response.source = :auto unless response.manual_after_api_failure?
    response.save!
  end

  def find_or_initialize_response(market_attribute)
    response = context.market_application.market_attribute_responses
      .find_by(market_attribute:)

    return response if response

    MarketAttributeResponse.build_for_attribute(
      market_attribute,
      market_application: context.market_application
    )
  end

  def extract_value_from_resource(market_attribute)
    context.bundled_data.data.public_send(market_attribute.api_key)
  end
end
