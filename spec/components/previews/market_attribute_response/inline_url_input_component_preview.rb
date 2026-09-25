# frozen_string_literal: true

# @label Inline URL Input Component
# @logical_path market_attribute_response
class MarketAttributeResponse::InlineUrlInputComponentPreview < Lookbook::Preview
  # @label Form - Manual Empty
  # @display bg_color "#f6f6f6"
  def form_manual_empty
    response = create_response(source: :manual, text: '')
    render_with_form(response)
  end

  # @label Form - Manual With URL
  # @display bg_color "#f6f6f6"
  def form_manual_with_url
    response = create_response(source: :manual, text: 'https://www.example.com/certificate')
    render_with_form(response)
  end

  # @label Form - Auto Source
  # @display bg_color "#f6f6f6"
  def form_auto
    response = create_response(source: :auto, text: 'https://api.example.com/certificate')
    render_with_form(response)
  end

  # @label Form - Manual After API Failure
  # @display bg_color "#f6f6f6"
  def form_manual_after_api_failure
    response = create_response(source: :manual_after_api_failure, text: '')
    render_with_form(response)
  end

  # @label Display - Web Manual With URL
  def display_web_manual_with_url
    response = create_response(source: :manual, text: 'https://www.example.com/certificate')
    render MarketAttributeResponse::InlineUrlInputComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Manual No URL
  def display_web_manual_no_url
    response = create_response(source: :manual, text: '')
    render MarketAttributeResponse::InlineUrlInputComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Web Auto (Hidden)
  def display_web_auto
    response = create_response(source: :auto, text: 'https://api.example.com/hidden')
    render MarketAttributeResponse::InlineUrlInputComponent.new(
      market_attribute_response: response,
      context: :web
    )
  end

  # @label Display - Buyer Auto (Visible)
  def display_buyer_auto
    response = create_response(source: :auto, text: 'https://api.example.com/visible-buyer')
    render MarketAttributeResponse::InlineUrlInputComponent.new(
      market_attribute_response: response,
      context: :buyer
    )
  end

  private

  # rubocop:disable Metrics/AbcSize
  def create_response(source:, text:)
    market_attribute = MarketAttribute.find_or_initialize_by(key: 'preview_inline_url_input_component') do |attr|
      attr.input_type = :inline_url_input
      attr.category_key = 'identite_entreprise'
      attr.subcategory_key = 'informations_generales'
      attr.mandatory = true
    end
    market_attribute.save! unless market_attribute.persisted?

    market_application = MarketApplication.first_or_create!(
      identifier: 'preview-app',
      public_market_id: PublicMarket.first&.id || create_public_market.id,
      siret: '73282932000074',
      attests_no_exclusion_motifs: false
    )

    response = MarketAttributeResponse::InlineUrlInput.find_or_initialize_by(
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
      editor_id: Editor.first&.id || create_editor.id,
      name: 'Marché de preview',
      deadline: 1.month.from_now,
      siret: '73282932000074',
      market_type_codes: [MarketType.find_or_create_by(code: 'works', deleted_at: nil).code],
      completed_at: Time.zone.now,
      sync_status: :sync_completed
    )
  end

  def create_editor
    Editor.create!(
      name: 'Preview Editor'
    )
  end

  def render_with_form(response)
    market_application = response.market_application

    render(MarketAttributeResponse::InlineUrlInputComponent.new(
      market_attribute_response: response,
      form: form_builder_for(market_application)
    ))
  end

  def form_builder_for(market_application)
    template = ActionView::Base.empty
    template.output_buffer = ActionView::OutputBuffer.new

    ActionView::Helpers::FormBuilder.new(
      :market_application,
      market_application,
      template,
      {}
    )
  end
end
