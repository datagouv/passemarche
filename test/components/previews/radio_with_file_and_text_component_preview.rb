# frozen_string_literal: true

# @label Radio With File And Text Component
# @logical_path market_attribute_response
class RadioWithFileAndTextComponentPreview < ViewComponent::Preview
  # @label Form - No Selected
  # @display bg_color "#f6f6f6"
  def form_no_selected
    response = create_response(source: :manual, radio_choice: 'no', text: '', with_file: false)
    render_with_form(response)
  end

  # @label Form - Yes Selected Without Content
  # @display bg_color "#f6f6f6"
  def form_yes_without_content
    response = create_response(source: :manual, radio_choice: 'yes', text: '', with_file: false)
    render_with_form(response)
  end

  # @label Form - Yes Selected With Text
  # @display bg_color "#f6f6f6"
  def form_yes_with_text
    response = create_response(source: :manual, radio_choice: 'yes', text: 'Description de la situation.', with_file: false)
    render_with_form(response)
  end

  # @label Form - Yes Selected With File
  # @display bg_color "#f6f6f6"
  def form_yes_with_file
    response = create_response(source: :manual, radio_choice: 'yes', text: '', with_file: true)
    render_with_form(response)
  end

  # @label Form - Yes Selected With Both
  # @display bg_color "#f6f6f6"
  def form_yes_with_both
    response = create_response(source: :manual, radio_choice: 'yes', text: 'Description complète.', with_file: true)
    render_with_form(response)
  end

  # @label Form - Auto Source
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(source: :auto, radio_choice: 'yes', text: 'Auto text', with_file: false)
    render_with_form(response)
  end

  # @label Display - Web No Selected
  def display_web_no
    response = create_response(source: :manual, radio_choice: 'no', text: '', with_file: false)
    render MarketAttributeResponse::RadioWithFileAndTextComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Yes Without Content
  def display_web_yes_empty
    response = create_response(source: :manual, radio_choice: 'yes', text: '', with_file: false)
    render MarketAttributeResponse::RadioWithFileAndTextComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Yes With Text
  def display_web_yes_with_text
    response = create_response(source: :manual, radio_choice: 'yes', text: "Description détaillée.\n\nAvec plusieurs paragraphes.", with_file: false)
    render MarketAttributeResponse::RadioWithFileAndTextComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Yes With Both
  def display_web_yes_with_both
    response = create_response(source: :manual, radio_choice: 'yes', text: 'Description avec document.', with_file: true)
    render MarketAttributeResponse::RadioWithFileAndTextComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Auto (Hidden)
  def display_web_auto
    response = create_response(source: :auto, radio_choice: 'yes', text: 'Texte automatique caché', with_file: true)
    render MarketAttributeResponse::RadioWithFileAndTextComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Buyer Auto (Visible)
  def display_buyer_auto
    response = create_response(source: :auto, radio_choice: 'yes', text: 'Texte automatique visible', with_file: true)
    render MarketAttributeResponse::RadioWithFileAndTextComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, radio_choice:, text:, with_file:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_radio_with_file_and_text_component') do |attr|
      attr.input_type = :radio_with_file_and_text
      attr.category_key = 'capacites_techniques_professionnelles'
      attr.subcategory_key = 'effectifs'
      attr.mandatory = true
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::RadioWithFileAndText.find_or_initialize_by(
      market_application:,
      market_attribute:
    )
    response.source = source
    response.value = { 'radio_choice' => radio_choice, 'text' => text }
    response.save! unless response.persisted?

    attach_sample_file(response) if with_file && !response.documents.attached?
    response
  end
  # rubocop:enable Metrics/AbcSize

  def attach_sample_file(response)
    response.documents.attach(
      io: StringIO.new('Sample content'),
      filename: 'document_complementaire.pdf',
      content_type: 'application/pdf'
    )
  end

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

    render(MarketAttributeResponse::RadioWithFileAndTextComponent.new(
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
