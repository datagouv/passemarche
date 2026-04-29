# frozen_string_literal: true

module Candidate
  class DashboardsController < Candidate::ApplicationController
    skip_before_action :require_candidate_authentication
    before_action :require_candidate_session

    def index
      @applications = MarketApplication
        .for_user(current_candidate)
        .for_siret(session_siret)
        .by_last_modification
        .includes(:public_market, :lots)
        .to_a
      @in_progress_count = @applications.count { |a| a.completed_at.nil? }
      @completed_count = @applications.count(&:completed_at?)
    end

    private

    def require_candidate_session
      return if current_candidate.present? && session_siret.present?

      session[:return_to] = request.original_url
      render 'candidate/sessions/new'
    end
  end
end
