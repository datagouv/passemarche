# frozen_string_literal: true

module PlatformReturnHelper
  def platform_return_url(market_application)
    market_application.public_market.editor.build_candidate_return_url(
      market: market_application.public_market,
      application: market_application
    )
  end
end
