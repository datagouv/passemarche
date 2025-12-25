# frozen_string_literal: true

# @label Realisations Livraisons Component
# @logical_path market_attribute_response
module MarketAttributeResponse
  class RealisationsLivraisonsComponentPreview < Lookbook::Preview
    # @label Form - Empty
    # @display bg_color "#f6f6f6"
    def form_empty
      response = create_response(source: :manual, value: { 'items' => {} })
      render_with_form(response)
    end

    # @label Form - Single Realisation
    # @display bg_color "#f6f6f6"
    def form_single_realisation
      response = create_response(
        source: :manual,
        value: {
          'items' => {
            '1702000000' => {
              'resume' => 'Construction batiment municipal',
              'date_debut' => '2022-01-15',
              'date_fin' => '2022-12-31',
              'montant' => '500000',
              'description' => 'Construction complete d\'un batiment municipal de 1200m2'
            }
          }
        }
      )
      render_with_form(response)
    end

    # @label Form - Multiple Realisations
    # @display bg_color "#f6f6f6"
    def form_multiple_realisations
      response = create_response(
        source: :manual,
        value: {
          'items' => {
            '1702000000' => {
              'resume' => 'Construction batiment municipal',
              'date_debut' => '2022-01-15',
              'date_fin' => '2022-12-31',
              'montant' => '500000',
              'description' => 'Construction complete d\'un batiment municipal de 1200m2'
            },
            '1702000001' => {
              'resume' => 'Renovation facade mairie',
              'date_debut' => '2023-06-01',
              'date_fin' => '2023-08-31',
              'montant' => '150000',
              'description' => 'Travaux de renovation de la facade principale'
            },
            '1702000002' => {
              'resume' => 'Amenagement espaces verts',
              'date_debut' => '2023-03-01',
              'date_fin' => '2023-05-15',
              'montant' => '75000',
              'description' => 'Creation d\'espaces verts et aires de jeux'
            }
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
            '1702000000' => {
              'resume' => 'Realisation auto-renseignee',
              'montant' => '100000'
            }
          }
        }
      )
      render_with_form(response)
    end

    # @label Display - Web Empty
    def display_web_empty
      response = create_response(source: :manual, value: nil)
      render RealisationsLivraisonsComponent.new(
        market_attribute_response: response,
        context: :web
      )
    end

    # @label Display - Web With Realisations
    def display_web_with_realisations
      response = create_response(
        source: :manual,
        value: {
          'items' => {
            '1702000000' => {
              'resume' => 'Construction batiment municipal',
              'date_debut' => '2022-01-15',
              'date_fin' => '2022-12-31',
              'montant' => '500000',
              'description' => 'Construction complete d\'un batiment municipal de 1200m2 incluant ' \
                               'gros oeuvre, second oeuvre et finitions haut de gamme.'
            },
            '1702000001' => {
              'resume' => 'Renovation facade mairie',
              'date_debut' => '2023-06-01',
              'date_fin' => '2023-08-31',
              'montant' => '150000',
              'description' => 'Travaux de renovation comprenant ravalement, isolation thermique ' \
                               'par l\'exterieur et remplacement des menuiseries.'
            }
          }
        }
      )
      render RealisationsLivraisonsComponent.new(
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
            '1702000000' => {
              'resume' => 'Realisation auto-renseignee',
              'date_debut' => '2022-01-01',
              'date_fin' => '2022-06-30',
              'montant' => '250000',
              'description' => 'Description auto-renseignee depuis l\'API'
            }
          }
        }
      )
      render RealisationsLivraisonsComponent.new(
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
            '1702000000' => {
              'resume' => 'Construction pour PDF',
              'date_debut' => '2022-01-15',
              'date_fin' => '2022-12-31',
              'montant' => '500000',
              'description' => 'Description pour le contexte PDF'
            }
          }
        }
      )
      render RealisationsLivraisonsComponent.new(
        market_attribute_response: response,
        context: :pdf
      )
    end

    private

    # rubocop:disable Metrics/AbcSize
    def create_response(source:, value:)
      market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_realisations_component') do |attr|
        attr.input_type = :realisations_livraisons
        attr.category_key = 'capacites_techniques_professionnelles'
        attr.subcategory_key = 'realisations'
        attr.mandatory = false
      end
      market_attribute.save! unless market_attribute.persisted?

      market_application = MarketApplication.first_or_create!(
        identifier: 'preview-app',
        public_market_id: PublicMarket.first&.id || create_public_market.id
      )

      response = MarketAttributeResponse::RealisationsLivraisons.find_or_initialize_by(
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

      render_inline(RealisationsLivraisonsComponent.new(
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
