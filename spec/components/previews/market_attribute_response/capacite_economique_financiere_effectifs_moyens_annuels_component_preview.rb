# frozen_string_literal: true

# @label Effectifs Moyens Annuels Component
# @logical_path market_attribute_response
module MarketAttributeResponse
  class CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponentPreview < Lookbook::Preview
    # @label Form - Empty
    # @display bg_color "#f6f6f6"
    def form_empty
      response = create_response(source: :manual, value: {})
      render_with_form(response)
    end

    # @label Form - Partial Data
    # @display bg_color "#f6f6f6"
    def form_partial
      response = create_response(
        source: :manual,
        value: {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 }
        }
      )
      render_with_form(response)
    end

    # @label Form - Complete Data
    # @display bg_color "#f6f6f6"
    def form_complete
      response = create_response(
        source: :manual,
        value: {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 },
          'year_3' => { 'year' => 2022, 'average_staff' => 35 }
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
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 }
        }
      )
      render_with_form(response)
    end

    # @label Display - Web Empty
    def display_web_empty
      response = create_response(source: :manual, value: nil)
      render CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Web Complete
    def display_web_complete
      response = create_response(
        source: :manual,
        value: {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 },
          'year_3' => { 'year' => 2022, 'average_staff' => 35 }
        }
      )
      render CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Web Auto (Hidden Values)
    def display_web_auto
      response = create_response(
        source: :auto,
        value: {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 }
        }
      )
      render CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Buyer Auto (Visible Values)
    def display_buyer_auto
      response = create_response(
        source: :auto,
        value: {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 }
        }
      )
      render CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent.new(
        market_attribute_response: response,
        context: :buyer
      )
    end

    # @label Display - PDF Context
    def display_pdf
      response = create_response(
        source: :manual,
        value: {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 }
        }
      )
      render CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent.new(
        market_attribute_response: response,
        context: :pdf
      )
    end

    private

    # rubocop:disable Metrics/AbcSize
    def create_response(source:, value:)
      market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_effectifs_component') do |attr|
        attr.input_type = :capacite_economique_financiere_effectifs_moyens_annuels
        attr.category_key = 'capacite_economique_financiere'
        attr.subcategory_key = 'effectifs'
        attr.mandatory = false
      end
      market_attribute.save! unless market_attribute.persisted?

      market_application = MarketApplication.first_or_create!(
        identifier: 'preview-app',
        public_market_id: PublicMarket.first&.id || create_public_market.id
      )

      response = MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels.find_or_initialize_by(
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

      render_inline(CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent.new(
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
