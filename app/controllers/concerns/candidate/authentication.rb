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
      return if current_candidate

      session[:return_to] = request.original_url
      @identifier = params[:identifier]
      render 'candidate/sessions/new'
    end
  end
end
