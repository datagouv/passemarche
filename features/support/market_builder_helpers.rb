# frozen_string_literal: true

module MarketBuilderHelpers
  DEFAULT_SIRET = '73282932000074'

  def setup_market_with_attribute(key:, **attrs)
    @editor ||= FactoryBot.create(:editor, :authorized_and_active)
    @public_market ||= FactoryBot.create(:public_market, :completed, editor: @editor)

    attr = MarketAttribute.find_or_create_by(key:) { |a| attrs.each { |k, v| a.send(:"#{k}=", v) } }
    @public_market.market_attributes << attr unless @public_market.market_attributes.include?(attr)
    attr
  end

  def setup_market_with_lots(*lot_names, editor: nil)
    @editor ||= editor || FactoryBot.create(:editor)
    @public_market ||= begin
      market = FactoryBot.create(:public_market, :completed, editor: @editor)
      attr = MarketAttribute.find_or_create_by(key: 'company_name') do |a|
        a.category_key = 'identite_entreprise'
        a.subcategory_key = 'market_information'
        a.input_type = :text_input
        a.mandatory = false
      end
      market.market_attributes << attr
      market
    end
    lot_names.map { |name| FactoryBot.create(:lot, public_market: @public_market, name:) }
  end

  def start_candidate_application(siret: DEFAULT_SIRET)
    @market_application = FactoryBot.create(:market_application, public_market: @public_market, siret:)
    authenticate_as_candidate_for(@market_application)
    @market_application
  end
end

World(MarketBuilderHelpers)
