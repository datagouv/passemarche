# frozen_string_literal: true

# @label Textarea Component
# @logical_path market_attribute_response
class TextareaComponentPreview < ViewComponent::Preview
  # @label Form - Manual Empty
  # @display bg_color "#f6f6f6"
  def form_manual_empty
    response = create_response(source: :manual, text: '')
    render_with_form(response)
  end

  # @label Form - Manual Filled
  # @display bg_color "#f6f6f6"
  def form_manual_filled
    response = create_response(source: :manual, text: "Description de l'entreprise.\n\nNotre société est spécialisée dans les services numériques.")
    render_with_form(response)
  end

  # @label Form - Auto Source
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(source: :auto, text: 'Texte rempli automatiquement depuis les données API')
    render_with_form(response)
  end

  # @label Form - Manual After API Failure
  # @display bg_color "#f6f6f6"
  def form_manual_after_api_failure
    response = create_response(source: :manual_after_api_failure, text: 'Texte de secours')
    render_with_form(response)
  end

  # @label Display - Web Manual
  def display_web_manual
    response = create_response(source: :manual, text: "Description de l'entreprise.\n\nNotre société est spécialisée.")
    render MarketAttributeResponse::TextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Auto (Hidden)
  def display_web_auto
    response = create_response(source: :auto, text: 'Valeur automatique cachée')
    render MarketAttributeResponse::TextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - PDF Manual
  def display_pdf_manual
    response = create_response(source: :manual, text: 'Description pour attestation PDF')
    render MarketAttributeResponse::TextareaComponent.new(
      market_attribute_response: response,
      context: :pdf
    )
  end

  # @label Display - Buyer Manual
  def display_buyer_manual
    response = create_response(source: :manual, text: 'Description visible par acheteur')
    render MarketAttributeResponse::TextareaComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  # @label Display - Buyer Auto (Visible)
  def display_buyer_auto
    response = create_response(source: :auto, text: 'Valeur automatique visible pour acheteur')
    render MarketAttributeResponse::TextareaComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, text:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_textarea_component') do |attr|
      attr.input_type = :textarea
      attr.category_key = 'identite_entreprise'
      attr.subcategory_key = 'informations_generales'
      attr.mandatory = true
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::Textarea.find_or_initialize_by(
      market_application:,
      market_attribute:
    )
    response.source = source
    response.value = { 'text' => text }
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

    render(MarketAttributeResponse::TextareaComponent.new(
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
