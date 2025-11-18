# frozen_string_literal: true

# @label Text Input Component
# @logical_path market_attribute_response
class TextInputComponentPreview < ViewComponent::Preview
  # @label Form - Manual Source
  # @display bg_color "#f6f6f6"
  def form_manual
    response = create_response(source: :manual, text: '')
    render_with_form(response)
  end

  # @label Form - Auto Source
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(source: :auto, text: 'Automatically filled text')
    render_with_form(response)
  end

  # @label Form - Manual After API Failure
  # @display bg_color "#f6f6f6"
  def form_manual_after_api_failure
    response = create_response(source: :manual_after_api_failure, text: 'Fallback text')
    render_with_form(response)
  end

  # @label Summary - Manual Source (Web)
  def summary_manual
    response = create_response(source: :manual, text: 'User-entered text')
    render MarketAttributeResponse::TextInputComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Summary - Auto Source (Web)
  def summary_auto
    response = create_response(source: :auto, text: 'Automatically filled text')
    render MarketAttributeResponse::TextInputComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Candidate Attestation - Manual Source (PDF)
  def candidate_attestation_manual
    response = create_response(source: :manual, text: 'User-entered text')
    render MarketAttributeResponse::TextInputComponent.new(
      market_attribute_response: response,
      context: :pdf
    )
  end

  # @label Candidate Attestation - Auto Source (PDF)
  def candidate_attestation_auto
    response = create_response(source: :auto, text: 'Automatically filled text')
    render MarketAttributeResponse::TextInputComponent.new(
      market_attribute_response: response,
      context: :pdf
    )
  end

  # @label Buyer Attestation - Manual Source (Buyer)
  def buyer_attestation_manual
    response = create_response(source: :manual, text: 'User-entered text')
    render MarketAttributeResponse::TextInputComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  # @label Buyer Attestation - Auto Source (Buyer)
  def buyer_attestation_auto
    response = create_response(source: :auto, text: 'Automatically filled text')
    render MarketAttributeResponse::TextInputComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, text:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_text_input') do |attr|
      attr.input_type = :text_input
      attr.category_key = 'identite_entreprise'
      attr.subcategory_key = 'informations_generales'
      attr.required = true
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::TextInput.find_or_initialize_by(
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

    render(MarketAttributeResponse::TextInputComponent.new(
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
