# frozen_string_literal: true

require 'csv'

class ExportSocleDeBaseCsvService < ApplicationServiceObject
  HEADERS = [
    'Clé',
    'Catégorie acheteur',
    'Sous-catégorie acheteur',
    'Nom acheteur',
    'Catégorie candidat',
    'Sous-catégorie candidat',
    'Nom candidat',
    'Obligatoire',
    'Source',
    'Type de saisie',
    'Position',
    'Types de marché'
  ].freeze

  def initialize(market_attributes:)
    super()
    @market_attributes = market_attributes
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
    [
      attribute.key,
      presenter.buyer_category_label,
      presenter.buyer_subcategory_label,
      presenter.buyer_name,
      presenter.candidate_category_label,
      presenter.candidate_subcategory_label,
      presenter.candidate_name,
      attribute.mandatory? ? 'Oui' : 'Non',
      presenter.source_badge,
      attribute.input_type&.humanize,
      attribute.position,
      attribute.market_types.map(&:code).join(', ')
    ]
  end
end
