# frozen_string_literal: true

class MarketApplication < ApplicationRecord
  include Completable
  include Syncable

  belongs_to :public_market
  has_one :editor, through: :public_market

  has_one_attached :attestation
  has_one_attached :documents_package
  has_many :market_attribute_responses, dependent: :destroy

  accepts_nested_attributes_for :market_attribute_responses, allow_destroy: true, reject_if: :all_blank

  validates :identifier, presence: true, uniqueness: true
  validates :siret, format: { with: /\A\d{14}\z/ }, allow_blank: true
  validate :market_must_be_completed
  validate :siret_must_be_valid
  validate :nested_attributes_valid

  before_validation :generate_identifier, on: :create

  def find_authorized_document(attachment_id)
    market_attribute_responses
      .where(type: MarketAttributeResponse.file_attachable_types)
      .flat_map(&:documents)
      .find { |doc| doc.id.to_s == attachment_id.to_s }
  end

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

  def nested_attributes_valid
    market_attribute_responses.each do |response|
      next if response.valid?

      response.errors.each do |error|
        errors.add("market_attribute_responses.#{error.attribute}", error.message)
      end
    end
  end
end
