# frozen_string_literal: true

class AuthMailerPreview < ActionMailer::Preview
  def magic_link
    user = User.new(email: 'candidat@example.com')
    url = 'http://localhost:3000/auth/verify?token=abc123&market_application_id=VR-2024-PREVIEW'
    market_name = 'Système d\'acquisition dynamique (SAD) pour la fourniture de matériels informatiques'

    AuthMailer.magic_link(user, url, market_name)
  end
end
