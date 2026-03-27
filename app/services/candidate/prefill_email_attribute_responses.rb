# frozen_string_literal: true

module Candidate
  class PrefillEmailAttributeResponses < ApplicationService
    def initialize(market_application:, candidate_email:)
      @market_application = market_application
      @candidate_email = candidate_email
    end

    def call
      return if candidate_email.blank?

      responses_by_attribute_id =
        market_application.market_attribute_responses.index_by(&:market_attribute_id)

      email_attributes.each do |attribute|
        response = responses_by_attribute_id[attribute.id] || build_email_response(attribute)
        response.text ||= candidate_email
      end
    end

    private

    attr_reader :market_application, :candidate_email

    def email_attributes
      market_application.public_market.market_attributes.select(&:email_input?)
    end

    def build_email_response(attribute)
      market_application.market_attribute_responses.build(
        market_attribute: attribute,
        type: MarketAttributeResponse.type_from_input_type(attribute.input_type)
      )
    end
  end
end
