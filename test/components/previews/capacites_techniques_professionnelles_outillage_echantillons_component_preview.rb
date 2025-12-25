# frozen_string_literal: true

# @label Outillage Echantillons Component
# @logical_path market_attribute_response
class CapacitesTechniquesProfessionnellesOutillageEchantillonsComponentPreview < ViewComponent::Preview
  # @label Form - Empty
  # @display bg_color "#f6f6f6"
  def form_empty
    response = create_response(source: :manual, value: { 'items' => {} })
    render_with_form(response)
  end

  # @label Form - Single Item
  # @display bg_color "#f6f6f6"
  def form_single_item
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'description' => 'Echantillon de mobilier urbain conforme aux normes PMR' }
        }
      }
    )
    render_with_form(response)
  end

  # @label Form - Multiple Items
  # @display bg_color "#f6f6f6"
  def form_multiple_items
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'description' => 'Echantillon de mobilier urbain' },
          '1702000001' => { 'description' => 'Photographie du prototype' },
          '1702000002' => { 'description' => 'Documentation technique' }
        }
      }
    )
    render_with_form(response)
  end

  # @label Form - Auto (Hidden)
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(
      source: :auto,
      value: {
        'items' => {
          '1702000000' => { 'description' => 'Echantillon auto' }
        }
      }
    )
    render_with_form(response)
  end

  # @label Display - Web Empty
  def display_web_empty
    response = create_response(source: :manual, value: nil)
    render MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web With Items
  def display_web_with_items
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'description' => 'Echantillon de mobilier urbain conforme aux normes PMR' },
          '1702000001' => { 'description' => 'Photographie du prototype fonctionnel' }
        }
      }
    )
    render MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Buyer Context
  def display_buyer
    response = create_response(
      source: :auto,
      value: {
        'items' => {
          '1702000000' => { 'description' => 'Echantillon auto-renseigne' }
        }
      }
    )
    render MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  # @label Display - PDF Context
  def display_pdf
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'description' => 'Echantillon pour PDF' }
        }
      }
    )
    render MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent.new(
      market_attribute_response: response,
      context: :pdf
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, value:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_echantillons_component') do |attr|
      attr.input_type = :capacites_techniques_professionnelles_outillage_echantillons
      attr.category_key = 'capacites_techniques_professionnelles'
      attr.subcategory_key = 'outillage'
      attr.mandatory = false
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillons
      .find_or_initialize_by(
        market_application:,
        market_attribute:
      )
    response.source = source
    response.value = value
    response.save! unless response.persisted?

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

  def render_with_form(response)
    market_application = response.market_application

    render(MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent.new(
      market_attribute_response: response,
      form: form_builder_for(market_application)
    ))
  end

  def form_builder_for(market_application)
    # Create a proper view context with all helpers available
    controller = ApplicationController.new
    controller.request = ActionDispatch::TestRequest.create
    view_context = controller.view_context

    ActionView::Helpers::FormBuilder.new(
      :market_application,
      market_application,
      view_context,
      {}
    )
  end
end
