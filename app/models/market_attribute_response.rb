class MarketAttributeResponse < ApplicationRecord
  belongs_to :market_application
  belongs_to :market_attribute

  # Source tracking for data origin
  # manual: filled by candidate manually
  # auto: automatically filled from API
  # manual_after_api_failure: filled manually after API call failed
  enum :source, {
    manual: 0,
    auto: 1,
    manual_after_api_failure: 2
  }

  # Simple mapping from input_type to STI class name
  INPUT_TYPE_MAP = {
    'file_upload' => 'FileUpload',
    'inline_file_upload' => 'InlineFileUpload',
    'text_input' => 'TextInput',
    'checkbox' => 'Checkbox',
    'textarea' => 'Textarea',
    'email_input' => 'EmailInput',
    'file_or_textarea' => 'FileOrTextarea',
    'phone_input' => 'PhoneInput',
    'checkbox_with_document' => 'CheckboxWithDocument',
    'radio_with_file_and_text' => 'RadioWithFileAndText',
    'radio_with_justification_required' => 'RadioWithJustificationRequired',
    'capacite_economique_financiere_chiffre_affaires_global_annuel' => 'CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel',
    'capacite_economique_financiere_effectifs_moyens_annuels' => 'CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels',
    'presentation_intervenants' => 'PresentationIntervenants',
    'realisations_livraisons' => 'RealisationsLivraisons',
    'capacites_techniques_professionnelles_outillage_echantillons' => 'CapacitesTechniquesProfessionnellesOutillageEchantillons',
    'url_input' => 'UrlInput',
    'inline_url_input' => 'InlineUrlInput'
  }.freeze

  validates :type, presence: true, inclusion: { in: INPUT_TYPE_MAP.values }

  before_validation :set_type_from_market_attribute, on: :create

  def self.file_attachable?
    false
  end

  def self.find_sti_class(type_name)
    "MarketAttributeResponse::#{type_name}".constantize
  end

  def self.sti_class_for_input_type(input_type)
    sti_class_name = INPUT_TYPE_MAP[input_type]
    unless sti_class_name
      valid_types = INPUT_TYPE_MAP.keys.join(', ')
      raise "Unknown input type '#{input_type}'. Valid types are: #{valid_types}"
    end

    "MarketAttributeResponse::#{sti_class_name}".constantize
  end

  def self.build_for_attribute(market_attribute, params = {})
    klass = sti_class_for_input_type(market_attribute.input_type)
    klass.new(params.merge(market_attribute:))
  end

  def self.type_from_input_type(input_type)
    INPUT_TYPE_MAP[input_type]
  end

  def self.sti_name
    name.demodulize
  end

  # Helper methods for source-based logic
  def manually_filled?
    manual? || manual_after_api_failure?
  end

  def should_display_badge?
    auto? || manual_after_api_failure?
  end

  def from_api_source?
    auto?
  end

  private

  def set_type_from_market_attribute
    return if type.present?
    return unless market_attribute

    self.type = INPUT_TYPE_MAP[market_attribute.input_type]
  end
end
