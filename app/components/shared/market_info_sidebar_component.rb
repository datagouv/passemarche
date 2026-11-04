# frozen_string_literal: true

class Shared::MarketInfoSidebarComponent < ViewComponent::Base
  Row = Data.define(:label, :value)

  # rubocop:disable Metrics/ParameterLists -- one kwarg per displayed row keeps call sites readable
  def initialize(buyer_label:, market_name:, typology_label:, market_types_label:, deadline_label:, deadline:)
    @rows = [
      Row.new(label: buyer_label, value: market_name),
      (Row.new(label: typology_label, value: market_types_label) if market_types_label.present?),
      Row.new(label: deadline_label, value: deadline)
    ].compact
  end
  # rubocop:enable Metrics/ParameterLists

  private

  attr_reader :rows
end
