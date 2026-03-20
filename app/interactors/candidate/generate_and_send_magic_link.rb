# frozen_string_literal: true

module Candidate
  class GenerateAndSendMagicLink < ApplicationInteractor
    delegate :user, :market_application, :host, :protocol, :reconnection, to: :context

    def call
      user.update!(authentication_token_sent_at: Time.current)
      context.magic_link_url = build_url(user.generate_token_for(:magic_link))

      send_magic_link_email
    end

    private

    def send_magic_link_email
      AuthMailer.magic_link(user, context.magic_link_url, market_application.public_market.name, reconnection:).deliver_later
    end

    def build_url(token)
      Rails.application.routes.url_helpers.verify_candidate_sessions_url(
        token:,
        market_application_id: market_application.identifier,
        host:,
        protocol: protocol.delete_suffix('://')
      )
    end
  end
end
