# frozen_string_literal: true

# @label Presentation Intervenants Component
# @logical_path market_attribute_response
class PresentationIntervenantsComponentPreview < ViewComponent::Preview
  # @label Form - Empty
  # @display bg_color "#f6f6f6"
  def form_empty
    response = create_response(source: :manual, value: { 'items' => {} })
    render_with_form(response)
  end

  # @label Form - Single Person
  # @display bg_color "#f6f6f6"
  def form_single_person
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'nom' => 'Dupont', 'prenoms' => 'Jean', 'titres' => 'Ingenieur informatique' }
        }
      }
    )
    render_with_form(response)
  end

  # @label Form - Multiple Persons
  # @display bg_color "#f6f6f6"
  def form_multiple_persons
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'nom' => 'Dupont', 'prenoms' => 'Jean', 'titres' => 'Ingenieur informatique' },
          '1702000001' => { 'nom' => 'Martin', 'prenoms' => 'Marie', 'titres' => 'Architecte logiciel' },
          '1702000002' => { 'nom' => 'Bernard', 'prenoms' => 'Pierre', 'titres' => 'Chef de projet' }
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
          '1702000000' => { 'nom' => 'Dupont', 'prenoms' => 'Jean' }
        }
      }
    )
    render_with_form(response)
  end

  # @label Display - Web Empty
  def display_web_empty
    response = create_response(source: :manual, value: nil)
    render MarketAttributeResponse::PresentationIntervenantsComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web With Persons
  def display_web_with_persons
    response = create_response(
      source: :manual,
      value: {
        'items' => {
          '1702000000' => { 'nom' => 'Dupont', 'prenoms' => 'Jean', 'titres' => 'Ingenieur informatique' },
          '1702000001' => { 'nom' => 'Martin', 'prenoms' => 'Marie', 'titres' => 'Architecte logiciel' }
        }
      }
    )
    render MarketAttributeResponse::PresentationIntervenantsComponent.new(
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
          '1702000000' => { 'nom' => 'Dupont', 'prenoms' => 'Jean' }
        }
      }
    )
    render MarketAttributeResponse::PresentationIntervenantsComponent.new(
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
          '1702000000' => { 'nom' => 'Dupont', 'prenoms' => 'Jean', 'titres' => 'Ingenieur' }
        }
      }
    )
    render MarketAttributeResponse::PresentationIntervenantsComponent.new(
      market_attribute_response: response,
      context: :pdf
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, value:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_intervenants_component') do |attr|
      attr.input_type = :presentation_intervenants
      attr.category_key = 'presentation'
      attr.subcategory_key = 'intervenants'
      attr.mandatory = false
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::PresentationIntervenants.find_or_initialize_by(
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

    render(MarketAttributeResponse::PresentationIntervenantsComponent.new(
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
