# frozen_string_literal: true

# @label Magic Link Email Component
class MagicLinkEmailComponentPreview < Lookbook::Preview
  # @label Default
  # @display bg_color "#f6f6f6"
  def default
    render MagicLinkEmailComponent.new(
      url: 'http://localhost:3000/auth/verify?token=abc123',
      market_name: "Système d'acquisition dynamique pour la fourniture de matériels informatiques"
    )
  end
end
