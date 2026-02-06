# frozen_string_literal: true

# Enhanced CSV row data using ActiveModel
class CsvRowData
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :key, :string
  attribute :category_key, :string
  attribute :subcategory_key, :string
  attribute :type, :string
  attribute :import, :string
  attribute :apifiable, :string
  attribute :services, :string
  attribute :fournitures, :string
  attribute :travaux, :string
  attribute :défense, :string
  attribute :line_number, :integer
  attribute :position, :integer

  attribute :obligatoire, :string

  # Category/subcategory labels from CSV
  attribute :category_acheteur, :string
  attribute :subcategory_acheteur, :string
  attribute :category_candidat, :string
  attribute :subcategory_candidat, :string

  # API-related attributes (using exact CSV column names)
  attribute :API, :string
  attribute :"Informations récupérées par l'API", :string

  SUPPORTED_TYPES = %w[
    checkbox_with_document
    document
    inline_document
    email
    file_or_textarea
    phone
    radio_with_file_and_text
    textarea
    texte
    capacite_economique_financiere_chiffre_affaires_global_annuel
    capacite_economique_financiere_effectifs_moyens_annuels
    presentation_intervenants
    realisations_livraisons
    capacites_techniques_professionnelles_outillage_echantillons
    inline_url_input
  ].freeze

  MARKET_TYPE_MAPPING = {
    'services' => 'services',
    'fournitures' => 'supplies',
    'travaux' => 'works',
    'défense' => 'defense'
  }.freeze

  INPUT_TYPE_MAPPING = {
    'checkbox_with_document' => :checkbox_with_document,
    'document' => :file_upload,
    'inline_document' => :inline_file_upload,
    'email' => :email_input,
    'file_or_textarea' => :file_or_textarea,
    'phone' => :phone_input,
    'radio_with_file_and_text' => :radio_with_file_and_text,
    'textarea' => :textarea,
    'texte' => :text_input,
    'capacite_economique_financiere_chiffre_affaires_global_annuel' => :capacite_economique_financiere_chiffre_affaires_global_annuel,
    'capacite_economique_financiere_effectifs_moyens_annuels' => :capacite_economique_financiere_effectifs_moyens_annuels,
    'presentation_intervenants' => :presentation_intervenants,
    'realisations_livraisons' => :realisations_livraisons,
    'capacites_techniques_professionnelles_outillage_echantillons' => :capacites_techniques_professionnelles_outillage_echantillons,
    'inline_url_input' => :inline_url_input
  }.freeze

  validates :key, presence: true, if: :should_import?
  validates :type, inclusion: { in: SUPPORTED_TYPES }, if: :should_import?
  validates :category_key, presence: true, if: :should_import?
  validates :subcategory_key, presence: true, if: :should_import?

  validate :import_requirements, if: :should_import?

  def initialize(raw_data = {}, line_number: nil, position: nil)
    @raw_data = raw_data if raw_data.is_a?(Hash)

    if raw_data.is_a?(Hash)
      known_attributes = extract_known_attributes(raw_data)
      super(known_attributes.merge(line_number:, position:))
    else
      super(raw_data)
    end
  end

  def importable?
    should_import? && valid?
  end

  def from_api?
    oui_to_boolean(apifiable)
  end

  def api_name
    self.API&.strip
  end

  def api_key
    public_send(:"Informations récupérées par l'API")&.strip
  end

  def applicable_market_types
    MARKET_TYPE_MAPPING.filter_map do |csv_column, code|
      code if oui_to_boolean_from_column(csv_column)
    end
  end

  def to_market_attribute_params
    {
      category_key:,
      subcategory_key:,
      input_type: mapped_input_type,
      api_name: api_name.presence,
      api_key: api_key.presence,
      position:,
      deleted_at: nil,
      mandatory: oui_to_boolean(obligatoire)
    }
  end

  def validation_summary
    return '✅ Valid for import' if importable?
    return '⏭️  Skipped (import not requested)' unless should_import?

    "❌ Invalid: #{errors.full_messages.join(', ')}"
  end

  def should_import?
    oui_to_boolean(import)
  end

  private

  def extract_known_attributes(raw_data)
    known_keys = self.class.attribute_names

    raw_data.select { |key, _| known_keys.include?(key.to_s) }
  end

  def oui_to_boolean(value)
    value.to_s.strip.downcase == 'oui'
  end

  def oui_to_boolean_from_column(column_name)
    return false unless @raw_data

    @raw_data[column_name]&.strip&.downcase == 'oui'
  end

  def mapped_input_type
    INPUT_TYPE_MAPPING.fetch(type) do
      raise ArgumentError, "Unsupported input type: #{type}"
    end
  end

  def import_requirements
    return unless should_import?

    errors.add(:key, 'cannot be blank for imported rows') if key.blank?

    return if SUPPORTED_TYPES.include?(type)

    errors.add(:type, "must be one of: #{SUPPORTED_TYPES.join(', ')}")
  end
end
