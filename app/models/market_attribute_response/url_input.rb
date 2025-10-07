class MarketAttributeResponse::UrlInput < MarketAttributeResponse
  include MarketAttributeResponse::TextValidatable

  URL_REGEX = %r{\A(https?://)?(www\.)?[a-z0-9-]+(\.[a-z0-9-]+)+([/?#][^\s]*)?\z}i

  validates :text, presence: true, format: {
    with: URL_REGEX,
    message: 'doit être une URL valide (ex: https://..., ou www...)'
  }

  before_save :normalize_url

  private

  def normalize_url
    return if text.blank? || text.start_with?('http://', 'https://')

    self.text = "https://#{text}"
  end
end
