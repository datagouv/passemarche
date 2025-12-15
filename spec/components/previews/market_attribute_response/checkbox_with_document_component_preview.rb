# frozen_string_literal: true

# @label Checkbox With Document Component
# @logical_path market_attribute_response
module MarketAttributeResponse
  class CheckboxWithDocumentComponentPreview < Lookbook::Preview
    # @label Form - Unchecked
    # @display bg_color "#f6f6f6"
    def form_unchecked
      response = create_response(source: :manual, checked: false, with_file: false)
      render_with_form(response)
    end

    # @label Form - Checked Without Document
    # @display bg_color "#f6f6f6"
    def form_checked_without_document
      response = create_response(source: :manual, checked: true, with_file: false)
      render_with_form(response)
    end

    # @label Form - Checked With Document
    # @display bg_color "#f6f6f6"
    def form_checked_with_document
      response = create_response(source: :manual, checked: true, with_file: true)
      render_with_form(response)
    end

    # @label Form - Auto Source
    # @display bg_color "#f6f6f6"
    def form_auto
      response = create_response(source: :auto, checked: true, with_file: false)
      render_with_form(response)
    end

    # @label Display - Web Unchecked
    def display_web_unchecked
      response = create_response(source: :manual, checked: false, with_file: false)
      render CheckboxWithDocumentComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Web Checked Without Document
    def display_web_checked_without_document
      response = create_response(source: :manual, checked: true, with_file: false)
      render CheckboxWithDocumentComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Web Checked With Document
    def display_web_checked_with_document
      response = create_response(source: :manual, checked: true, with_file: true)
      render CheckboxWithDocumentComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Web Auto (Hidden)
    def display_web_auto
      response = create_response(source: :auto, checked: true, with_file: true)
      render CheckboxWithDocumentComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Buyer Auto (Visible)
    def display_buyer_auto
      response = create_response(source: :auto, checked: true, with_file: true)
      render CheckboxWithDocumentComponent.new(
        market_attribute_response: response,
        context: :buyer
      )
    end

    private

    # rubocop:disable Metrics/AbcSize
    def create_response(source:, checked:, with_file:)
      market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_checkbox_with_document_component') do |attr|
        attr.input_type = :checkbox_with_document
        attr.category_key = 'capacite_economique_financiere'
        attr.subcategory_key = 'assurance'
        attr.mandatory = true
      end
      market_attribute.save! unless market_attribute.persisted?

      market_application = MarketApplication.first_or_create!(
        identifier: 'preview-app',
        public_market_id: PublicMarket.first&.id || create_public_market.id
      )

      response = MarketAttributeResponse::CheckboxWithDocument.find_or_initialize_by(
        market_application:,
        market_attribute:
      )
      response.source = source
      response.value = { 'checked' => checked }
      response.save! unless response.persisted?

      attach_sample_file(response) if with_file && !response.documents.attached?
      response
    end
    # rubocop:enable Metrics/AbcSize

    def attach_sample_file(response)
      response.documents.attach(
        io: StringIO.new('Sample content'),
        filename: 'attestation_assurance.pdf',
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

      render_inline(CheckboxWithDocumentComponent.new(
        market_attribute_response: response,
        form: form_builder_for(market_application)
      ))
    end

    def form_builder_for(market_application)
      template = ActionView::Base.empty
      template.output_buffer = ActiveSupport::SafeBuffer.new

      ActionView::Helpers::FormBuilder.new(
        :market_application,
        market_application,
        template,
        {}
      )
    end
  end
end
