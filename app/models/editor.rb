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
  validate :validate_url_fields

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

  def build_buyer_return_url(market:)
    return nil if buyer_return_url.blank?

    append_identifiers(buyer_return_url, market:)
  end

  def build_candidate_return_url(market:, application:)
    return nil if candidate_return_url.blank?

    append_identifiers(candidate_return_url, market:, application:)
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

  def validate_url_fields
    %i[
      completion_webhook_url
      buyer_return_url
      candidate_return_url
    ].each do |attribute|
      validate_url_format(attribute) if public_send(attribute).present?
    end
  end

  def append_identifiers(base_url, market:, application: nil)
    uri = URI.parse(base_url)
    params = Rack::Utils.parse_nested_query(uri.query)
    params['market_identifier'] = market.identifier
    params['application_identifier'] = application.identifier if application
    uri.query = Rack::Utils.build_nested_query(params)
    uri.to_s
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
