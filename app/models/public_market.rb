# frozen_string_literal: true

class PublicMarket < ApplicationRecord
  include UniqueAssociationValidator
  include Completable
  include Syncable

  belongs_to :editor

  has_and_belongs_to_many :market_attributes
  has_many :market_applications, dependent: :destroy

  validates :identifier, presence: true, uniqueness: true
  validates :name, presence: true
  validates :deadline, presence: true
  validates :siret, presence: true
  validates :market_type_codes, presence: true, length: { minimum: 1 }
  validate :must_have_valid_market_type_codes
  validate :siret_must_be_valid
  validates_uniqueness_of_association :market_attributes

  before_validation :generate_identifier, on: :create

  def defense_industry?
    market_type_codes.any?('defense')
  end

  def add_market_attributes(new_attributes)
    all_attributes = (market_attributes.to_a + Array(new_attributes)).uniq
    self.market_attributes = all_attributes
    save!
  end

  # this naming sucks
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

    self.identifier = IdentifierGenerationService.call
  end

  def siret_must_be_valid
    return if siret.blank?
    return if SiretValidationService.call(siret)

    errors.add(:siret, 'Le numéro de SIRET saisi est invalide ou non reconnu')
  end
end
