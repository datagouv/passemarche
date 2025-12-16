# frozen_string_literal: true

# @label File Or Textarea Component
# @logical_path market_attribute_response
class FileOrTextareaComponentPreview < ViewComponent::Preview
  # @label Form - Manual Empty
  # @display bg_color "#f6f6f6"
  def form_manual_empty
    response = create_response(source: :manual, text: '', with_file: false)
    render_with_form(response)
  end

  # @label Form - Manual With Text
  # @display bg_color "#f6f6f6"
  def form_manual_with_text
    response = create_response(source: :manual, text: "Description de l'activité.\n\nDétails supplémentaires.", with_file: false)
    render_with_form(response)
  end

  # @label Form - Manual With File
  # @display bg_color "#f6f6f6"
  def form_manual_with_file
    response = create_response(source: :manual, text: '', with_file: true)
    render_with_form(response)
  end

  # @label Form - Auto Source
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(source: :auto, text: 'Auto-filled text', with_file: false)
    render_with_form(response)
  end

  # @label Display - Web Manual Empty
  def display_web_manual_empty
    response = create_response(source: :manual, text: '', with_file: false)
    render MarketAttributeResponse::FileOrTextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Manual With Text
  def display_web_manual_with_text
    response = create_response(source: :manual, text: "Description détaillée.\n\nAvec plusieurs paragraphes.", with_file: false)
    render MarketAttributeResponse::FileOrTextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Manual With File
  def display_web_manual_with_file
    response = create_response(source: :manual, text: '', with_file: true)
    render MarketAttributeResponse::FileOrTextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Manual With Both
  def display_web_manual_with_both
    response = create_response(source: :manual, text: 'Description avec fichier joint.', with_file: true)
    render MarketAttributeResponse::FileOrTextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Auto (Hidden)
  def display_web_auto
    response = create_response(source: :auto, text: 'Texte automatique caché', with_file: true)
    render MarketAttributeResponse::FileOrTextareaComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Buyer Auto (Visible)
  def display_buyer_auto
    response = create_response(source: :auto, text: 'Texte automatique visible', with_file: true)
    render MarketAttributeResponse::FileOrTextareaComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, text:, with_file:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_file_or_textarea_component') do |attr|
      attr.input_type = :file_or_textarea
      attr.category_key = 'identite_entreprise'
      attr.subcategory_key = 'informations_generales'
      attr.mandatory = true
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::FileOrTextarea.find_or_initialize_by(
      market_application:,
      market_attribute:
    )
    response.source = source
    response.value = { 'text' => text }
    response.save! unless response.persisted?

    attach_sample_file(response) if with_file && !response.documents.attached?
    response
  end
  # rubocop:enable Metrics/AbcSize

  def attach_sample_file(response)
    response.documents.attach(
      io: StringIO.new('Sample content'),
      filename: 'document_joint.pdf',
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

    render(MarketAttributeResponse::FileOrTextareaComponent.new(
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
