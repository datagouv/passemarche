# frozen_string_literal: true

# @label File Upload Component
# @logical_path market_attribute_response
class FileUploadComponentPreview < ViewComponent::Preview
  # @label Form - Manual No Files
  # @display bg_color "#f6f6f6"
  def form_manual_no_files
    response = create_response(source: :manual, with_file: false)
    render_with_form(response)
  end

  # @label Form - Manual With File
  # @display bg_color "#f6f6f6"
  def form_manual_with_file
    response = create_response(source: :manual, with_file: true)
    render_with_form(response)
  end

  # @label Form - Auto Source
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(source: :auto, with_file: true)
    render_with_form(response)
  end

  # @label Form - Manual After API Failure
  # @display bg_color "#f6f6f6"
  def form_manual_after_api_failure
    response = create_response(source: :manual_after_api_failure, with_file: false)
    render_with_form(response)
  end

  # @label Display - Web Manual No Files
  def display_web_manual_no_files
    response = create_response(source: :manual, with_file: false)
    render MarketAttributeResponse::FileUploadComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Manual With Files
  def display_web_manual_with_files
    response = create_response(source: :manual, with_file: true)
    render MarketAttributeResponse::FileUploadComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Auto (Hidden)
  def display_web_auto
    response = create_response(source: :auto, with_file: true)
    render MarketAttributeResponse::FileUploadComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - PDF Manual
  def display_pdf_manual
    response = create_response(source: :manual, with_file: true)
    render MarketAttributeResponse::FileUploadComponent.new(
      market_attribute_response: response,
      context: :pdf
    )
  end

  # @label Display - Buyer Manual
  def display_buyer_manual
    response = create_response(source: :manual, with_file: true)
    render MarketAttributeResponse::FileUploadComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  # @label Display - Buyer Auto (Visible)
  def display_buyer_auto
    response = create_response(source: :auto, with_file: true)
    render MarketAttributeResponse::FileUploadComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, with_file:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_file_upload_component') do |attr|
      attr.input_type = :file_upload
      attr.category_key = 'identite_entreprise'
      attr.subcategory_key = 'informations_generales'
      attr.mandatory = true
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id
    )

    response = MarketAttributeResponse::FileUpload.find_or_initialize_by(
      market_application:,
      market_attribute:
    )
    response.source = source
    response.save! unless response.persisted?

    attach_sample_file(response) if with_file && !response.documents.attached?
    response
  end
  # rubocop:enable Metrics/AbcSize

  def attach_sample_file(response)
    response.documents.attach(
      io: StringIO.new('Sample PDF content'),
      filename: 'document_exemple.pdf',
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

    render(MarketAttributeResponse::FileUploadComponent.new(
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
