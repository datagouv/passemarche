# frozen_string_literal: true

class MarketApplication < ApplicationRecord
  belongs_to :public_market
  has_one :editor, through: :public_market

  validates :identifier, presence: true, uniqueness: true
  validates :siret, format: { with: /\A\d{14}\z/ }, allow_blank: true
  validate :market_must_be_completed
  validate :siret_must_be_valid

  before_validation :generate_identifier, on: :create

  private

  def generate_identifier
    return if identifier.present?

    self.identifier = IdentifierGenerationService.call
  end

  def market_must_be_completed
    return unless public_market

    errors.add(:public_market, 'must be completed') unless public_market.sync_completed?
  end

  def siret_must_be_valid
    return if siret.blank?
    return if SiretValidationService.call(siret)

    errors.add(:siret, 'Le numéro de SIRET saisi est invalide ou non reconnu, veuillez vérifier votre saisie.')
  end
end
