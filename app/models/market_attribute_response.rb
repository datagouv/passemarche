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
    'radio_with_justification_optional' => 'RadioWithJustificationOptional',
    'capacite_economique_financiere_chiffre_affaires_global_annuel' => 'CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel',
    'capacite_economique_financiere_effectifs_moyens_annuels' => 'CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels',
    'presentation_intervenants' => 'PresentationIntervenants',
    'realisations_livraisons' => 'RealisationsLivraisons',
    'capacites_techniques_professionnelles_outillage_echantillons' => 'CapacitesTechniquesProfessionnellesOutillageEchantillons',
    'url_input' => 'UrlInput',
    'inline_url_input' => 'InlineUrlInput'
  }.freeze

  # List of STI types that can have file attachments.
  # These responses will have their documents included in the buyer's ZIP package.
  FILE_ATTACHABLE_TYPES = %w[
    FileUpload
    InlineFileUpload
    CheckboxWithDocument
    RadioWithFileAndText
    RadioWithJustificationRequired
    RadioWithJustificationOptional
    FileOrTextarea
    PresentationIntervenants
    RealisationsLivraisons
    CapacitesTechniquesProfessionnellesOutillageEchantillons
  ].freeze

  validates :type, presence: true, inclusion: { in: INPUT_TYPE_MAP.values }

  # Scope to retrieve only responses that can have file attachments.
  # Used by GenerateDocumentsPackage to collect all documents for the ZIP.
  scope :with_file_attachments, -> { where(type: FILE_ATTACHABLE_TYPES) }

  before_validation :set_type_from_market_attribute, on: :create

  def self.file_attachable?
    false
  end

  def run_validations!
    # Skip all validations if this response is not part of the current validation step
    return true unless should_validate_for_current_step?

    super
  end

  def should_validate_for_current_step?
    # If no market_application or no step specified, validate everything (e.g., summary step)
    return true if market_application.nil? || market_application.current_validation_step.nil?

    # Get the IDs of responses that should be validated for this step
    valid_response_ids = market_application.response_ids_for_step(market_application.current_validation_step)

    # If no responses for this step (empty step like company_identification), skip validation
    return false if valid_response_ids.empty?

    # Only validate if this response is in the list
    valid_response_ids.include?(id)
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

  private

  def set_type_from_market_attribute
    return if type.present?
    return unless market_attribute

    self.type = INPUT_TYPE_MAP[market_attribute.input_type]
  end
end
