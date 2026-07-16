# frozen_string_literal: true

Given('the editor webhook responds with success') do
  @editor.update!(completion_webhook_url: 'https://editor.example.com/webhook')
  stub_request(:post, @editor.completion_webhook_url)
    .to_return(status: 200, body: 'OK')
end

Given('a completed but non-published market with multi-type lots exists for the current editor') do
  works_type = MarketType.find_or_create_by!(code: 'works')
  services_type = MarketType.find_or_create_by!(code: 'services')

  @completed_market = FactoryBot.create(:public_market, :completed,
    editor: @editor,
    market_type_codes: [works_type.code, services_type.code])

  common_attribute = FactoryBot.create(:market_attribute,
    key: 'common_scope_field',
    category_key: 'test_common_category',
    subcategory_key: 'test_common_subcategory',
    market_types: [works_type, services_type])
  @completed_market.add_market_attributes([common_attribute])

  FactoryBot.create(:lot, public_market: @completed_market, name: 'Lot travaux', market_type: works_type)
  FactoryBot.create(:lot, public_market: @completed_market, name: 'Lot services', market_type: services_type)
end

Given('a configuration summary PDF is already attached to the market') do
  @completed_market.configuration_summary.attach(
    io: StringIO.new('old configuration summary'),
    filename: 'old.pdf',
    content_type: 'application/pdf'
  )
  @previous_configuration_summary_blob_id = @completed_market.configuration_summary.blob.id
end

Then('a configuration summary PDF should be attached to the market') do
  @completed_market.reload
  expect(@completed_market.configuration_summary).to be_attached
end

Then('the configuration summary PDF should have been replaced') do
  @completed_market.reload
  expect(@completed_market.configuration_summary.blob.id).not_to eq(@previous_configuration_summary_blob_id)
end

Then('I should see the download configuration summary button') do
  expect(page).to have_link(I18n.t('buyer.sync_status.download_configuration_summary'))
end
