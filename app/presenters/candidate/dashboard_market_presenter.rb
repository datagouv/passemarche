# frozen_string_literal: true

module Candidate
  class DashboardMarketPresenter
    attr_reader :public_market

    delegate :name, :buyer_display_name, to: :public_market

    def self.collection(public_markets, market_applications)
      applications_by_market = market_applications
        .where(public_market_id: public_markets.map(&:id))
        .includes(:lots, grouping_member: { grouping: :mandataire_grouping_member })
        .group_by(&:public_market_id)

      public_markets.map { |public_market| new(public_market, applications_by_market.fetch(public_market.id, [])) }
    end

    def initialize(public_market, market_applications)
      @public_market = public_market
      @market_applications = market_applications
    end

    def applications
      @applications ||= @market_applications
        .map { |market_application| DashboardApplicationPresenter.new(market_application, public_market:) }
        .sort_by { |application| [application.position, -application.updated_at.to_f] }
    end
  end
end
