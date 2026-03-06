# frozen_string_literal: true

class MagicLinkEmailComponent < ViewComponent::Base
  def initialize(url:, market_name:)
    @url = url
    @market_name = market_name
  end

  private

  def logo_data_uri
    image_path = Rails.root.join('app/assets/images/passe-marche-logo-email.jpg')
    base64 = Base64.strict_encode64(File.binread(image_path))
    "data:image/jpeg;base64,#{base64}"
  end
end
