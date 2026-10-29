# frozen_string_literal: true

class Candidate::DashboardMarketCardComponent < ViewComponent::Base
  with_collection_parameter :market

  def initialize(market:)
    @market = market
  end

  private

  attr_reader :market
end
