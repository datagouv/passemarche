# frozen_string_literal: true

module Candidate
  class DashboardsController < Candidate::ApplicationController
    skip_before_action :require_candidate_authentication
    before_action :require_candidate_session

    def index
      base_scope = MarketApplication
        .for_user(current_candidate)
        .for_siret(session_siret)
      @in_progress_count = base_scope.in_progress.count
      @completed_count = base_scope.completed.count
      @applications = base_scope
        .by_last_modification
        .includes(:public_market, :lots)
    end

    private

    def require_candidate_session
      return if current_candidate.present? && session_siret.present?

      session[:return_to] = request.original_url
      render 'candidate/sessions/new'
    end
  end
end
