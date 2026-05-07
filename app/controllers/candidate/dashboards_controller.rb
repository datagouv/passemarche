# frozen_string_literal: true

module Candidate
  class DashboardsController < Candidate::ApplicationController
    include Pagy::Method

    def index
      base_scope = MarketApplication
        .for_user(current_candidate)
        .for_siret(session_siret)
      @in_progress_count = base_scope.in_progress.count
      @completed_count = base_scope.completed.count
      @pagy, @applications = pagy(
        base_scope.by_last_modification.includes(:public_market, :lots),
        limit: 10
      )
    end
  end
end
