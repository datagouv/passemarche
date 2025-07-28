# frozen_string_literal: true

class PublicMarket < ApplicationRecord
  include FormFieldConfiguration

  belongs_to :editor

  validates :identifier, presence: true, uniqueness: true
  validates :market_name, presence: true
  validates :deadline, presence: true
  validates :market_type, presence: true

  before_validation :generate_identifier, on: :create

  def completed?
    completed_at.present?
  end

  def complete!
    update!(completed_at: Time.current)
  end

  private

  def generate_identifier
    return if identifier.present?

    year = Time.current.year
    unique_number = (Time.current.to_f * 1_000_000).to_i + SecureRandom.random_number(1000)
    suffix = unique_number.to_s(36).upcase.rjust(12, '0')[-12..]
    self.identifier = "VR-#{year}-#{suffix}"
  end
end
