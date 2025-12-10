# frozen_string_literal: true

class Editor < ApplicationRecord
  has_many :public_markets, dependent: :destroy

  encrypts :webhook_secret

  before_validation :generate_client_id, on: :create
  before_validation :generate_client_secret, on: :create
  after_create :sync_to_doorkeeper!

  validates :name, presence: true, uniqueness: true
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true
  validate :validate_webhook_urls

  scope :authorized, -> { where(authorized: true) }
  scope :active, -> { where(active: true) }
  scope :authorized_and_active, -> { authorized.active }
  scope :with_webhook_configured, -> { where.not(completion_webhook_url: nil) }

  def authorized_and_active?
    authorized? && active?
  end

  def doorkeeper_application
    return @doorkeeper_application if defined?(@doorkeeper_application)

    @doorkeeper_application = CustomDoorkeeperApplication.find_by(uid: client_id)
  end

  def ensure_doorkeeper_application!
    EditorSyncService.call(self)
  end

  def sync_to_doorkeeper!
    EditorSyncService.call(self)
  end

  def generate_webhook_secret!
    generate_webhook_secret
    save!
  end

  def generate_webhook_secret
    self.webhook_secret = SecureRandom.hex(32)
  end

  def webhook_configured?
    completion_webhook_url.present?
  end

  def webhook_signature(payload)
    return nil if webhook_secret.blank?

    OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, payload)
  end

  def build_redirect_url(market:, application: nil)
    return nil if redirect_url.blank?

    uri = URI.parse(redirect_url)
    params = Rack::Utils.parse_nested_query(uri.query)
    params['market_identifier'] = market.identifier
    params['application_identifier'] = application.identifier if application
    uri.query = Rack::Utils.build_nested_query(params)
    uri.to_s
  end

  private

  def generate_client_id
    return if client_id.present?

    self.client_id = SecureRandom.hex(16)
  end

  def generate_client_secret
    return if client_secret.present?

    self.client_secret = SecureRandom.hex(32)
  end

  def validate_webhook_urls
    validate_url_format(:completion_webhook_url) if completion_webhook_url.present?
    validate_url_format(:redirect_url) if redirect_url.present?
  end

  def validate_url_format(attribute)
    url_value = send(attribute)
    uri = URI.parse(url_value)

    if Rails.env.production? && uri.scheme != 'https'
      errors.add(attribute, :https_required)
    elsif !uri.scheme.in?(%w[http https])
      errors.add(attribute, :invalid_url)
    end
  rescue URI::InvalidURIError
    errors.add(attribute, :invalid_url)
  end
end
