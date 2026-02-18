# frozen_string_literal: true

Given('the following market attributes with subcategories exist:') do |table|
  MarketAttribute.delete_all
  table.hashes.each do |row|
    subcategory = Subcategory.find_by!(key: row['subcategory_key'])
    attr = create(:market_attribute,
      key: row['key'],
      category_key: row['category_key'],
      subcategory_key: row['subcategory_key'],
      subcategory:,
      mandatory: row['mandatory'] == 'true',
      api_name: row['api_name'].presence,
      api_key: row['api_name'].present? ? 'test_key' : nil)

    next if row['market_types'].blank?

    codes = row['market_types'].split(',').map(&:strip)
    codes.each do |code|
      market_type = MarketType.find_by!(code:)
      attr.market_types << market_type
    end
  end
end

When('I search for {string}') do |query|
  visit admin_socle_de_base_index_path(query:)
end

When('I filter by market type {string}') do |code|
  market_type = MarketType.find_by!(code:)
  visit admin_socle_de_base_index_path(market_type_id: market_type.id)
end

When('I filter by category {string}') do |category_key|
  visit admin_socle_de_base_index_path(category: category_key)
end

When('I filter by source {string}') do |source|
  visit admin_socle_de_base_index_path(source:)
end

When('I filter by category {string} and source {string}') do |category_key, source|
  visit admin_socle_de_base_index_path(category: category_key, source:)
end

Then('I should see a row for {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  expect(page).to have_css("tr[data-item-id='#{attribute.id}']")
end

When('I click the reset filters link') do
  click_link I18n.t('admin.socle_de_base.filters.reset')
end
