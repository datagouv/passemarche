# frozen_string_literal: true

Given('a multi-type public market with scope attributes exists') do
  works_type    = MarketType.find_or_create_by!(code: 'works')
  services_type = MarketType.find_or_create_by!(code: 'services')

  @editor = create(:editor)
  @multi_public_market = create(:public_market, :completed, editor: @editor,
    name: 'Marché multi-types avec badges')
  @multi_public_market.market_type_codes = %w[works services]
  @multi_public_market.save!

  @lot_works    = create(:lot, public_market: @multi_public_market, name: 'Lot travaux',
    market_type: works_type)
  @lot_services = create(:lot, public_market: @multi_public_market, name: 'Lot services',
    market_type: services_type)

  @shared_attr = create(:market_attribute, :text_input,
    key: 'shared_field',
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@multi_public_market],
    market_types: [works_type, services_type])

  @works_attr = create(:market_attribute, :text_input,
    key: 'works_specific_field',
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@multi_public_market],
    market_types: [works_type])

  @services_attr = create(:market_attribute, :text_input,
    key: 'services_specific_field',
    category_key: 'identite_entreprise',
    subcategory_key: 'identification',
    public_markets: [@multi_public_market],
    market_types: [services_type])
end

Given('a candidate starts an application with one lot of each type') do
  @market_application = create(:market_application,
    public_market: @multi_public_market,
    siret: '73282932000074')
  @market_application.lots = [@lot_works, @lot_services]
  authenticate_as_candidate_for(@market_application)
end

Given('a candidate starts an application with only a works lot') do
  @market_application = create(:market_application,
    public_market: @multi_public_market,
    siret: '73282932000074')
  @market_application.lots = [@lot_works]
  authenticate_as_candidate_for(@market_application)
end

When('the candidate visits the wizard step for scope attributes') do
  visit "/candidate/market_applications/#{@market_application.identifier}/identification"
end

Then('they should see a scope badge for {string} on the works-specific field') do |type|
  fieldset_element = find('.fr-fieldset__element', text: /#{@works_attr.key.humanize}/)
  within(fieldset_element) do
    expect(page).to have_css('.market-type-badge', text: I18n.t("market_types.#{type}"))
  end
end

Then('they should see a scope badge for {string} on the services-specific field') do |type|
  fieldset_element = find('.fr-fieldset__element', text: /#{@services_attr.key.humanize}/)
  within(fieldset_element) do
    expect(page).to have_css('.market-type-badge', text: I18n.t("market_types.#{type}"))
  end
end

Then('they should see a commun scope badge on the shared field') do
  fieldset_element = find('.fr-fieldset__element', text: /#{@shared_attr.key.humanize}/)
  within(fieldset_element) do
    expect(page).to have_css('.market-scope-tags .fr-tag',
      text: I18n.t('buyer.public_markets.form_config.scope_commun_badge'))
  end
end

Then('they should not see any scope badges') do
  expect(page).not_to have_css('.market-scope-tags')
end
