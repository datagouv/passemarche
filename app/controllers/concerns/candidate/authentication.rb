# frozen_string_literal: true

module Candidate
  module Authentication
    extend ActiveSupport::Concern

    included do
      helper_method :current_candidate
    end

    private

    def current_candidate
      return @current_candidate if defined?(@current_candidate)

      @current_candidate = User.find_by(id: session[:user_id])
    end

    def require_candidate_authentication
      return if candidate_authenticated?

      clear_candidate_authentication_session
      session[:return_to] = request.original_url
      render 'candidate/sessions/new'
    end

    def ensure_market_application_in_session
      session[:market_application_identifier] ||= @market_application.identifier
    end

    def session_siret
      @session_siret ||= MarketApplication
        .find_by(identifier: session[:market_application_identifier])
        &.siret
    end

    def candidate_authenticated?
      return false unless current_candidate && @market_application

      ensure_market_application_in_session

      return @market_application.siret == session_siret if @market_application.user_id == current_candidate.id

      session[:market_application_identifier] == @market_application.identifier &&
        @market_application.accessible_by?(current_candidate)
    end

    def clear_candidate_authentication_session
      session.delete(:user_id)
      session.delete(:market_application_identifier)
    end
  end
end
