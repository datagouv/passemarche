# frozen_string_literal: true

module Candidate
  class SessionsController < ::ApplicationController
    def create
      result = Candidate::RequestMagicLink.call(magic_link_request_params)

      if result.success?
        store_reconnection_context(result)
        store_magic_link_url(result)
        redirect_to sent_candidate_sessions_path
      else
        @errors = result.errors
        render 'candidate/sessions/new', status: :unprocessable_content
      end
    end

    def sent
      @reconnection_market_name = session.delete(:reconnection_market_name)
      @magic_link_url = session.delete(:magic_link_url)
    end

    def verify
      user = User.find_by_token_for(:magic_link, params[:token])
      market_application = MarketApplication.find_by(identifier: params[:market_application_id])

      return invalid_token unless user && market_application&.accessible_by?(user)

      sign_in_candidate(user, market_application)
    end

    def destroy
      session.delete(:user_id)
      session.delete(:market_application_identifier)
      redirect_to root_path
    end

    private

    def sign_in_candidate(user, market_application)
      reconnection = market_application.user_id.present?
      market_application.update!(user:) unless reconnection
      session[:user_id] = user.id
      session[:market_application_identifier] = market_application.identifier
      redirect_to session.delete(:return_to) ||
                  step_candidate_market_application_path(market_application.identifier, :company_identification)
    end

    def magic_link_request_params
      {
        email: params[:email],
        siret: params[:siret],
        market_application_id: params[:market_application_id],
        host: request.host_with_port,
        protocol: request.protocol
      }
    end

    def store_reconnection_context(result)
      return unless result.reconnection

      session[:reconnection_market_name] = result.market_application.public_market.name
    end

    def store_magic_link_url(result)
      return unless Rails.env.sandbox? || Rails.env.development? || Rails.env.staging?

      session[:magic_link_url] = result.magic_link_url
    end

    def invalid_token
      redirect_to root_path, alert: t('candidate.sessions.invalid_token')
    end
  end
end
