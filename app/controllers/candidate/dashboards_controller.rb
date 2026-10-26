# frozen_string_literal: true

module Candidate
  class DashboardsController < Candidate::ApplicationController
    include Pagy::Method

    def index
      base_scope = MarketApplication
        .for_user(current_candidate)
        .for_siret(session_siret)
      status_counts = Candidate::DashboardApplicationPresenter.status_counts(base_scope)
      @in_progress_count = status_counts[:in_progress]
      @completed_count = status_counts[:completed]
      @pagy, public_markets = pagy(PublicMarket.by_latest_application_among(base_scope), limit: 10)
      @markets = Candidate::DashboardMarketPresenter.collection(public_markets, base_scope)
    end
  end
end
