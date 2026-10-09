# frozen_string_literal: true

module Candidate
  module MagicLinkSession
    extend ActiveSupport::Concern

    private

    def store_magic_link_url(magic_link_url)
      return unless Rails.env.sandbox? || Rails.env.development? || Rails.env.staging?

      session[:magic_link_url] = magic_link_url
    end
  end
end
