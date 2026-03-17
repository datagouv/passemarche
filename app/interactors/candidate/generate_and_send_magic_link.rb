# frozen_string_literal: true

module Candidate
  class GenerateAndSendMagicLink < ApplicationInteractor
    delegate :user, :market_application, :host, :protocol, to: :context

    def call
      user.update!(authentication_token_sent_at: Time.current)
      token = user.generate_token_for(:magic_link)
      url = build_url(token)

      AuthMailer.magic_link(user, url, market_application.public_market.name).deliver_later
    end

    private

    def build_url(token)
      "#{protocol}#{host}/auth/verify?token=#{token}&market_application_id=#{market_application.identifier}"
    end
  end
end
