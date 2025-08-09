# frozen_string_literal: true

class PublicMarket < ApplicationRecord
  include UniqueAssociationValidator

  belongs_to :editor

  has_and_belongs_to_many :market_attributes

  enum :sync_status, { sync_pending: 0, sync_processing: 1, sync_completed: 2, sync_failed: 3 }, default: :sync_pending, validate: true

  validates :identifier, presence: true, uniqueness: true
  validates :name, presence: true
  validates :deadline, presence: true
  validates :market_type_codes, presence: true, length: { minimum: 1 }
  validate :must_have_valid_market_type_codes
  validates_uniqueness_of_association :market_attributes

  before_validation :generate_identifier, on: :create

  def completed?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.zone.now)
  end

  def sync_in_progress?
    sync_pending? || sync_processing?
  end

  def defense_industry?
    market_type_codes.any?('defense')
  end

  def add_market_attributes(new_attributes)
    all_attributes = (market_attributes.to_a + Array(new_attributes)).uniq
    self.market_attributes = all_attributes
    save!
  end

  def sync_optional_market_attributes(selected_attributes)
    required_attributes = market_attributes.required
    all_attributes = (required_attributes + Array(selected_attributes)).uniq
    self.market_attributes = all_attributes
    save!
  end

  private

  def must_have_valid_market_type_codes
    check_valid_market_type_codes

    errors.add(:market_type_codes, :cannot_be_alone) if market_type_codes.one? && market_type_codes.first == 'defense'
  end

  def check_valid_market_type_codes
    return if market_type_codes.blank?

    valid_codes = MarketType.where(code: market_type_codes).pluck(:code)
    invalid_codes = market_type_codes - valid_codes

    return if invalid_codes.empty?

    errors.add(:market_type_codes, :invalid_codes, codes: invalid_codes.join(', '))
  end

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
