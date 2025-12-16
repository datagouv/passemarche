# frozen_string_literal: true

# @label Qualiopi API Display
# @logical_path market_attribute_response/api_display
class QualiopiComponentPreview < ViewComponent::Preview
  # @label All Certifications Active
  # @display bg_color "#f6f6f6"
  def all_certified
    response = create_response(
      action_formation: true,
      bilan_competences: true,
      validation_acquis_experience: true,
      apprentissage: true,
      obtention_via_unite_legale: true
    )
    render_component(response)
  end

  # @label Partial Certifications
  # @display bg_color "#f6f6f6"
  def partial_certified
    response = create_response(
      action_formation: true,
      bilan_competences: false,
      validation_acquis_experience: true,
      apprentissage: false,
      obtention_via_unite_legale: false
    )
    render_component(response)
  end

  # @label No Certifications
  # @display bg_color "#f6f6f6"
  def none_certified
    response = create_response(
      action_formation: false,
      bilan_competences: false,
      validation_acquis_experience: false,
      apprentissage: false,
      obtention_via_unite_legale: false
    )
    render_component(response)
  end

  # @label With Specialites
  # @display bg_color "#f6f6f6"
  def with_specialites
    response = create_response(
      action_formation: true,
      bilan_competences: true,
      validation_acquis_experience: false,
      apprentissage: false,
      obtention_via_unite_legale: true,
      specialites: [
        { 'libelle' => 'Formation continue' },
        { 'libelle' => 'Accompagnement VAE' },
        { 'libelle' => 'Bilan de competences' }
      ]
    )
    render_component(response)
  end

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def create_response(**certification_options)
    specialites = certification_options.delete(:specialites) || []

    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_qualiopi') do |attr|
      attr.input_type = :inline_file_upload
      attr.category_key = 'capacites_techniques_professionnelles'
      attr.subcategory_key = 'certificats_qualite'
      attr.mandatory = false
      attr.api_name = 'carif_oref'
      attr.api_key = 'qualiopi'
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::InlineFileUpload.find_or_initialize_by(
      market_application:,
      market_attribute:
    )
    response.source = :auto
    response.value = {
      'certification_qualiopi' => certification_options.transform_keys(&:to_s),
      'specialites' => specialites
    }
    response.save!(validate: false)
    response
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def create_public_market
    PublicMarket.create!(
      identifier: 'preview-market',
      editor_id: Editor.first&.id || create_editor.id
    )
  end

  def create_editor
    Editor.create!(
      name: 'Preview Editor',
      oauth_application_uid: 'preview-uid'
    )
  end

  def render_component(response)
    render MarketAttributeResponse::ApiDisplay::QualiopiComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end
end
