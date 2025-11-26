class MarketAttributeResponse::UrlInput < MarketAttributeResponse
  include MarketAttributeResponse::TextValidatable

  URL_REGEX = %r{\A(https?://)?(www\.)?[a-z0-9-]+(\.[a-z0-9-]+)+([/?#][^\s]*)?\z}i

  validates :text, format: { with: URL_REGEX, message: :invalid_url }, allow_blank: true

  before_save :normalize_url

  private

  def normalize_url
    return if text.blank? || text.start_with?('http://', 'https://')

    self.text = "https://#{text}"
  end
end
