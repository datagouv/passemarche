# frozen_string_literal: true

class PublicMarket < ApplicationRecord
  belongs_to :editor

  has_and_belongs_to_many :market_attributes

  validates :identifier, presence: true, uniqueness: true
  validates :name, presence: true
  validates :deadline, presence: true
  validate :must_have_valid_market_type_codes

  before_validation :generate_identifier, on: :create

  def completed?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.zone.now)
  end

  def defense_industry?
    market_type_codes.any?('defense')
  end

  private

  def must_have_valid_market_type_codes
    errors.add(:market_type_codes, :empty) if market_type_codes.empty?

    check_valid_market_type_codes

    errors.add(:market_type_codes, :cannot_be_alone) if market_type_codes.one? && market_type_codes.first == 'defense'
  end

  def check_valid_market_type_codes
    market_type_codes.each do |code|
      MarketType.find_by(code: code).tap do |mt|
        errors.add(:market_type_codes, :invalid, code: code) unless mt
      end
    end
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
