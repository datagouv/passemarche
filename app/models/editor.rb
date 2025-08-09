# frozen_string_literal: true

class Editor < ApplicationRecord
  has_many :public_markets, dependent: :destroy

  encrypts :webhook_secret

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
    @doorkeeper_application ||= CustomDoorkeeperApplication.find_by(uid: client_id)
  end

  def ensure_doorkeeper_application!
    EditorSyncService.call(self)
  end

  def sync_to_doorkeeper!
    EditorSyncService.call(self)
  end

  def generate_webhook_secret!
    self.webhook_secret = SecureRandom.hex(32)
  end

  def webhook_configured?
    completion_webhook_url.present?
  end

  private

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
