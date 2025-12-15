# frozen_string_literal: true

# @label Textarea Field
# @logical_path market_attribute_response/fields
module MarketAttributeResponse
  module Fields
    class TextareaFieldComponentPreview < Lookbook::Preview
      # @label Empty
      # @display bg_color "#f6f6f6"
      def empty
        response = create_response(text: '')
        form = form_builder_for(response)

        render TextareaFieldComponent.new(
          form:,
          attribute_response: response
        )
      end

      # @label With Content
      # @display bg_color "#f6f6f6"
      def with_content
        response = create_response(text: "Ceci est un exemple de texte multiligne.\n\nIl peut contenir plusieurs paragraphes et détails sur l'entreprise ou le projet.")
        form = form_builder_for(response)

        render TextareaFieldComponent.new(
          form:,
          attribute_response: response
        )
      end

      # @label With Validation Error
      # @display bg_color "#f6f6f6"
      def with_error
        response = create_response(text: '')
        response.errors.add(:text, 'Ce champ est obligatoire')
        form = form_builder_for(response)

        render TextareaFieldComponent.new(
          form:,
          attribute_response: response
        )
      end

      # @label Read-only Mode
      # @display bg_color "#f6f6f6"
      def readonly
        response = create_response(text: 'Ce contenu ne peut pas être modifié.')
        form = form_builder_for(response)

        render TextareaFieldComponent.new(
          form:,
          attribute_response: response,
          readonly: true
        )
      end

      # @label Custom Rows (10)
      # @display bg_color "#f6f6f6"
      def custom_rows
        response = create_response(text: 'Textarea avec 10 lignes.')
        form = form_builder_for(response)

        render TextareaFieldComponent.new(
          form:,
          attribute_response: response,
          rows: 10
        )
      end

      private

      def create_response(text:)
        market_application = find_or_create_market_application
        market_attribute = find_or_create_market_attribute

        response = MarketAttributeResponse::Textarea.find_or_initialize_by(
          market_application:,
          market_attribute:
        )
        response.source = :manual
        response.value = { 'text' => text }
        response.save! unless response.persisted?
        response
      end

      def find_or_create_market_application
        MarketApplication.first || create_market_application
      end

      def create_market_application
        public_market = PublicMarket.first || create_public_market
        MarketApplication.create!(
          identifier: 'preview-textarea',
          public_market:
        )
      end

      def create_public_market
        editor = Editor.first || Editor.create!(
          name: 'Preview Editor',
          oauth_application_uid: 'preview-uid'
        )
        PublicMarket.create!(
          identifier: 'preview-market',
          editor:
        )
      end

      def find_or_create_market_attribute
        MarketAttribute.find_by(key: 'preview_textarea') ||
          MarketAttribute.create!(
            key: 'preview_textarea',
            input_type: :textarea,
            category_key: 'identite_entreprise',
            subcategory_key: 'informations_generales',
            mandatory: false
          )
      end

      def form_builder_for(response)
        template = ActionView::Base.empty
        template.output_buffer = ActiveSupport::SafeBuffer.new

        ActionView::Helpers::FormBuilder.new(
          :market_attribute_response,
          response,
          template,
          {}
        )
      end
    end
  end
end
