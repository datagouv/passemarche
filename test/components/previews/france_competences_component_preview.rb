# frozen_string_literal: true

# @label France Competences API Display
# @logical_path market_attribute_response/api_display
class FranceCompetencesComponentPreview < ViewComponent::Preview
  # @label Single Active Habilitation
  # @display bg_color "#f6f6f6"
  def single_habilitation_active
    response = create_response(
      habilitations: [
        {
          'actif' => true,
          'date_actif' => '2023-01-15',
          'date_fin_enregistrement' => '2026-01-15',
          'habilitation_pour_former' => true,
          'habilitation_pour_organiser_l_evaluation' => true,
          'sirets_organismes_certificateurs' => ['12345678901234']
        }
      ]
    )
    render_component(response)
  end

  # @label Single Inactive Habilitation
  # @display bg_color "#f6f6f6"
  def single_habilitation_inactive
    response = create_response(
      habilitations: [
        {
          'actif' => false,
          'date_actif' => '2020-01-15',
          'date_fin_enregistrement' => '2023-01-15',
          'habilitation_pour_former' => false,
          'habilitation_pour_organiser_l_evaluation' => false
        }
      ]
    )
    render_component(response)
  end

  # @label Multiple Habilitations
  # @display bg_color "#f6f6f6"
  def multiple_habilitations
    response = create_response(
      habilitations: [
        {
          'actif' => true,
          'date_actif' => '2023-06-01',
          'date_fin_enregistrement' => '2026-06-01',
          'habilitation_pour_former' => true,
          'habilitation_pour_organiser_l_evaluation' => false,
          'sirets_organismes_certificateurs' => ['11111111111111']
        },
        {
          'actif' => true,
          'date_actif' => '2024-01-10',
          'habilitation_pour_former' => true,
          'habilitation_pour_organiser_l_evaluation' => true,
          'sirets_organismes_certificateurs' => %w[22222222222222 33333333333333]
        },
        {
          'actif' => false,
          'date_actif' => '2019-03-20',
          'date_fin_enregistrement' => '2022-03-20',
          'habilitation_pour_former' => false,
          'habilitation_pour_organiser_l_evaluation' => false
        }
      ]
    )
    render_component(response)
  end

  # @label Minimal Data
  # @display bg_color "#f6f6f6"
  def minimal_data
    response = create_response(
      habilitations: [
        {
          'actif' => true,
          'habilitation_pour_former' => true,
          'habilitation_pour_organiser_l_evaluation' => false
        }
      ]
    )
    render_component(response)
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(habilitations:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_france_competences') do |attr|
      attr.input_type = :inline_url_input
      attr.category_key = 'capacites_techniques_professionnelles'
      attr.subcategory_key = 'certificats_qualite'
      attr.mandatory = false
      attr.api_name = 'carif_oref'
      attr.api_key = 'france_competence'
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::InlineUrlInput.find_or_initialize_by(
      market_application:,
      market_attribute:
    )
    response.source = :auto
    response.value = { 'habilitations' => habilitations }
    response.save!(validate: false)
    response
  end
  # rubocop:enable Metrics/AbcSize

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
    render MarketAttributeResponse::ApiDisplay::FranceCompetencesComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end
end
