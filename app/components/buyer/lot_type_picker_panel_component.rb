# frozen_string_literal: true

class Buyer::LotTypePickerPanelComponent < ViewComponent::Base
  def initialize(picker_market_types:)
    @picker_market_types = picker_market_types
  end

  private

  attr_reader :picker_market_types

  def picker_options
    MarketType::LOT_TYPE_CODES.filter_map do |code|
      market_type = picker_market_types[code]
      next unless market_type

      { code:, market_type:, icon: ApplicationHelper::MARKET_TYPE_CONFIGS.dig(code, :icon_only),
        background: ApplicationHelper::MARKET_TYPE_CONFIGS.dig(code, :bg) }
    end
  end
end
