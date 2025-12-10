# frozen_string_literal: true

class MarketAttribute < ApplicationRecord
  include UniqueAssociationValidator

  has_and_belongs_to_many :market_types
  has_and_belongs_to_many :public_markets
  has_many :market_attribute_responses, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :category_key, :subcategory_key, presence: true
  validates_uniqueness_of_association :market_types, :public_markets

  enum :input_type, {
    file_upload: 0,
    text_input: 1,
    checkbox: 2,
    textarea: 3,
    email_input: 4,
    phone_input: 5,
    checkbox_with_document: 6,
    file_or_textarea: 7,
    capacite_economique_financiere_chiffre_affaires_global_annuel: 8,
    capacite_economique_financiere_effectifs_moyens_annuels: 9,
    presentation_intervenants: 10,
    radio_with_file_and_text: 11,
    realisations_livraisons: 12,
    capacites_techniques_professionnelles_outillage_echantillons: 13,
    url_input: 14,
    radio_with_justification_required: 15,
    inline_file_upload: 16,
    inline_url_input: 17,
    radio_with_justification_optional: 18
  }

  scope :mandatory, -> { where(mandatory: true) }
  scope :optional, -> { where(mandatory: false) }
  scope :from_api, -> { where.not(api_name: nil) }
  scope :active, -> { where(deleted_at: nil) }

  scope :ordered, lambda {
    order(:mandatory, :category_key, :subcategory_key, :key)
  }

  # Check if this attribute's data comes from an API
  def from_api?
    api_name.present?
  end
end
