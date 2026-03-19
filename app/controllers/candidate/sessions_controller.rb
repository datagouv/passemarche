# frozen_string_literal: true

module Candidate
  class SessionsController < ApplicationController
    def create
      result = Candidate::RequestMagicLink.call(
        email: params[:email],
        siret: params[:siret],
        host: request.host_with_port,
        protocol: request.protocol
      )

      if result.success?
        redirect_to sent_candidate_sessions_path
      else
        @errors = result.errors
        render 'candidate/sessions/new', status: :unprocessable_content
      end
    end

    def sent; end

    def verify
      user = User.find_by_token_for(:magic_link, params[:token])
      market_application = MarketApplication.find_by(identifier: params[:market_application_id])

      return invalid_token unless user && market_application&.accessible_by?(user)

      sign_in_candidate(user, market_application)
    end

    def destroy
      session.delete(:user_id)
      redirect_to root_path
    end

    private

    def sign_in_candidate(user, market_application)
      market_application.update!(user:) if market_application.user_id.nil?
      session[:user_id] = user.id
      redirect_to session.delete(:return_to) ||
                  step_candidate_market_application_path(market_application.identifier, :company_identification)
    end

    def invalid_token
      redirect_to root_path, alert: t('candidate.sessions.invalid_token')
    end
  end
end
