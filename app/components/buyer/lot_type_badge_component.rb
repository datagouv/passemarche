# frozen_string_literal: true

class Buyer::LotTypeBadgeComponent < ViewComponent::Base
  def initialize(lot:)
    @lot = lot
  end

  private

  attr_reader :lot

  def effective_market_type
    lot.effective_market_type
  end

  def overridden?
    lot.market_type.present? && lot.platform_market_type.present? && lot.market_type != lot.platform_market_type
  end

  def platform_source_label(market_type_code)
    "#{t("market_types.#{market_type_code}")} (#{t('buyer.public_markets.lot_config.platform_source')})".upcase
  end
end
