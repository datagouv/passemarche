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

    assign_value_to_response(response, value)
    response.source = :auto unless response.manual_after_api_failure?

    # For complex economic capacity responses, allow saving even if incomplete
    # The user will complete the missing data in the form
    if complex_economic_capacity_response?(response, value)
      response.save(validate: false)
    else
      response.save!
    end
  end

  def assign_value_to_response(response, value)
    if value.is_a?(Hash) && value.key?(:io)
      attach_document_to_response(response, value)
    elsif complex_economic_capacity_response?(response, value)
      assign_parsed_json_value(response, value)
    else
      response.text = value
    end
  end

  def complex_economic_capacity_response?(response, value)
    response.class.name.include?('CapaciteEconomique') && value.is_a?(String)
  end

  def assign_parsed_json_value(response, value)
    parsed_data = JSON.parse(value)
    response.value = parsed_data
  rescue JSON::ParserError
    response.text = value
  end

  def attach_document_to_response(response, document_hash)
    return unless response.respond_to?(:documents)

    existing_document = response.documents.find do |doc|
      doc.metadata['api_name'] == context.api_name
    end

    existing_document.purge if existing_document.present?
    response.documents.attach(document_hash)
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
