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
    capacites_techniques_professionnelles_realisations_livraisons_cinq_ans: 12,
    capacites_techniques_professionnelles_outillage_echantillons: 13
  }

  scope :required, -> { where(required: true) }
  scope :additional, -> { where(required: false) }
  scope :from_api, -> { where(from_api: true) }
  scope :active, -> { where(deleted_at: nil) }

  scope :ordered, lambda {
    order(:required, :category_key, :subcategory_key, :key)
  }
end
