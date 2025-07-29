# frozen_string_literal: true

class PublicMarket < ApplicationRecord
  include FieldConstants
  include OptionalFieldsValidation

  belongs_to :editor

  validates :identifier, presence: true, uniqueness: true
  validates :market_name, presence: true
  validates :deadline, presence: true
  validates :market_type, inclusion: { in: MARKET_TYPES }

  before_validation :generate_identifier, on: :create

  def completed?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.zone.now)
  end

  private

  def generate_identifier
    return if identifier.present?

    self.identifier = build_identifier
  end

  def build_identifier
    now = Time.zone.now
    year = now.year
    suffix = generate_unique_suffix(now)
    "VR-#{year}-#{suffix}"
  end

  def generate_unique_suffix(time)
    unique_number = (time.to_f * 1_000_000).to_i + SecureRandom.random_number(1000)
    unique_number.to_s(36).upcase.rjust(12, '0')[-12..]
  end
end
