# frozen_string_literal: true

# @label OPQIBI API Display
# @logical_path market_attribute_response/api_display
module MarketAttributeResponse
  module ApiDisplay
    class OpqibiComponentPreview < Lookbook::Preview
      # @label With Valid Dates
      # @display bg_color "#f6f6f6"
      def with_valid_dates
        response = create_response(
          date_delivrance: '2024-01-15',
          duree_validite: '4 ans'
        )
        render_component(response)
      end

      # @label With URL and Dates
      # @display bg_color "#f6f6f6"
      def with_url_and_dates
        response = create_response(
          url: 'https://www.opqibi.com/certificat/12345',
          date_delivrance: '2023-06-20',
          duree_validite: '3 ans'
        )
        render_component(response)
      end

      # @label Only Date Delivrance
      # @display bg_color "#f6f6f6"
      def only_date_delivrance
        response = create_response(
          date_delivrance: '2024-03-10',
          duree_validite: nil
        )
        render_component(response)
      end

      # @label Only Duree Validite
      # @display bg_color "#f6f6f6"
      def only_duree_validite
        response = create_response(
          date_delivrance: nil,
          duree_validite: '5 ans'
        )
        render_component(response)
      end

      private

      # rubocop:disable Metrics/AbcSize
      def create_response(url: nil, date_delivrance: nil, duree_validite: nil)
        market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_opqibi') do |attr|
          attr.input_type = :inline_url_input
          attr.category_key = 'capacites_techniques_professionnelles'
          attr.subcategory_key = 'certificats_qualite'
          attr.mandatory = false
          attr.api_name = 'opqibi'
          attr.api_key = 'data'
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
        response.value = {
          'text' => url,
          'date_delivrance_certificat' => date_delivrance,
          'duree_validite_certificat' => duree_validite
        }.compact
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
        render OpqibiComponent.new(
          market_attribute_response: response,
          context: :web
        )
      end
    end
  end
end
