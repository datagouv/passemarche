# frozen_string_literal: true

class MarketAttribute < ApplicationRecord
  has_paper_trail on: %i[create update],
    ignore: %i[position updated_at created_at]

  include UniqueAssociationValidator

  attr_accessor :configuration_mode

  CATEGORY_TABS = %w[
    identite_entreprise
    motifs_exclusion
    capacite_economique_financiere
    capacites_techniques_professionnelles
  ].freeze

  belongs_to :subcategory, optional: true

  has_and_belongs_to_many :market_types
  has_and_belongs_to_many :public_markets
  has_many :market_attribute_responses, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :category_key, :subcategory_key, presence: true
  validates :input_type, presence: true
  validates :api_name, :api_key, presence: true, if: :from_api?
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
  scope :manual, -> { where(api_name: nil) }
  scope :active, -> { where(deleted_at: nil) }
  scope :ordered, -> { order(:position) }
  scope :by_category, ->(category_key) { where(category_key:) }
  scope :by_subcategory, ->(subcategory_key) { where(subcategory_key:) }
  scope :by_source, ->(source) { source.to_sym == :api ? from_api : manual }
  scope :by_market_type, ->(market_type_id) { joins(:market_types).where(market_types: { id: market_type_id }) }

  def from_api?
    api_name.present?
  end

  def manual?
    !from_api?
  end

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def active?
    deleted_at.nil?
  end

  def archived?
    deleted_at.present?
  end

  def resolved_buyer_name
    buyer_name.presence || key.humanize
  end

  def resolved_buyer_description
    buyer_description.presence
  end

  def resolved_candidate_name
    candidate_name.presence || key.humanize
  end

  def resolved_candidate_description
    candidate_description.presence
  end
end
