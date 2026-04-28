# frozen_string_literal: true

When('I click the {string} link for {string}') do |link_text, key|
  attribute = MarketAttribute.find_by!(key:)
  within("tr[data-item-id='#{attribute.id}']") do
    click_link link_text
  end
end

When('I visit the field detail page for {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  visit admin_socle_de_base_path(attribute)
end

When('I visit the edit page for {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  visit edit_admin_socle_de_base_path(attribute)
end

When('I click the back link') do
  click_link I18n.t('admin.socle_de_base.show.back')
end

When('I click the cancel link') do
  click_link I18n.t('admin.socle_de_base.edit.cancel')
end

When('I click the archive button') do
  attribute = MarketAttribute.last
  page.driver.submit :patch, archive_admin_socle_de_base_path(attribute), {}
end

When('I toggle the mandatory checkbox') do
  find('input[name="market_attribute[mandatory]"]').click
end

When('I submit the edit form') do
  click_button I18n.t('admin.socle_de_base.edit.submit')
end

Then('I should see the field detail page for {string}') do |key|
  attribute = MarketAttribute.find_by!(key:)
  presenter = SocleDeBasePresenter.new(attribute)
  expect(page).to have_css('h1', text: presenter.field_name)
end

Then('I should see the configuration section showing {string}') do |mode|
  expect(page).to have_css('h2', text: I18n.t('admin.socle_de_base.show.configuration'))
  expect(page).to have_content(mode)
end

Then('I should be on the socle de base page') do
  expect(page).to have_css('h1', text: I18n.t('admin.socle_de_base.title'))
end

Then('I should see the general info section') do
  expect(page).to have_css('h2', text: I18n.t('admin.socle_de_base.show.general_info'))
  expect(page).to have_content(I18n.t('admin.socle_de_base.show.field_type'))
end

Then('I should see the mandatory badge') do
  expect(page).to have_css('.fr-badge', text: I18n.t('admin.socle_de_base.badges.mandatory'))
end

Then('I should see the buyer view section') do
  expect(page).to have_css('h3', text: I18n.t('admin.socle_de_base.show.buyer_view'))
end

Then('I should see the candidate view section') do
  expect(page).to have_css('h3', text: I18n.t('admin.socle_de_base.show.candidate_view'))
end

Then('I should see the edit form title {string}') do |title|
  expect(page).to have_css('h1', text: title)
end

Then('I should see the input type select') do
  expect(page).to have_css('select[name="market_attribute[input_type]"]')
end

Then('I should see the mandatory checkbox') do
  expect(page).to have_css('input[name="market_attribute[mandatory]"][type="checkbox"]')
end

Then('I should see market type checkboxes') do
  expect(page).to have_css('input[name="market_attribute[market_type_ids][]"][type="checkbox"]')
end

Then('I should see a success notice') do
  expect(page).to have_content(I18n.t('admin.socle_de_base.update.success'))
end

Then('the field {string} should be archived') do |key|
  attribute = MarketAttribute.find_by!(key:)
  expect(attribute.deleted_at).not_to be_nil
end
