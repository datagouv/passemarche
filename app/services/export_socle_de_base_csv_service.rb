# frozen_string_literal: true

require 'csv'

class ExportSocleDeBaseCsvService
  HEADERS = [
    'Clé',
    'Catégorie (clé)',
    'Sous-catégorie (clé)',
    'Catégorie acheteur',
    'Sous-catégorie acheteur',
    'Nom acheteur',
    'Description acheteur',
    'Catégorie candidat',
    'Sous-catégorie candidat',
    'Nom candidat',
    'Description candidat',
    'Obligatoire',
    'Source (api_name)',
    'Clé API',
    'Type de saisie',
    'Position',
    'Types de marché'
  ].freeze

  attr_reader :result

  def initialize(market_attributes:)
    @market_attributes = market_attributes.to_a
  end

  def perform
    @result = {
      csv_data: generate_csv,
      filename: "socle-de-base-#{Date.current}.csv"
    }
  end

  private

  def generate_csv
    CSV.generate(headers: true, col_sep: ';') do |csv|
      csv << HEADERS
      @market_attributes.each { |attr| csv << build_row(attr) }
    end
  end

  def build_row(attribute)
    presenter = SocleDeBasePresenter.new(attribute)
    build_identity_columns(attribute) +
      build_label_columns(presenter) +
      build_metadata_columns(attribute)
  end

  def build_identity_columns(attribute)
    [attribute.key, attribute.category_key, attribute.subcategory_key]
  end

  def build_label_columns(presenter)
    [
      presenter.buyer_category_label, presenter.buyer_subcategory_label,
      presenter.buyer_name, presenter.buyer_description,
      presenter.candidate_category_label, presenter.candidate_subcategory_label,
      presenter.candidate_name, presenter.candidate_description
    ]
  end

  def build_metadata_columns(attribute)
    [
      attribute.mandatory? ? 'Oui' : 'Non',
      attribute.api_name, attribute.api_key, attribute.input_type,
      attribute.position, attribute.market_types.map(&:code).join(', ')
    ]
  end
end
