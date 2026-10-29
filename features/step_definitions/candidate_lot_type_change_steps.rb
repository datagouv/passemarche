# frozen_string_literal: true

Given('the multi-type market asks for the Qualibat certificate on works lots') do
  @qualibat_attribute = create(:market_attribute, :file_upload, :from_api, key: 'certificat_qualibat',
    api_name: 'qualibat', api_key: 'qualibat', category_key: 'capacites_techniques_professionnelles',
    subcategory_key: 'capacites_techniques_professionnelles_certificats',
    public_markets: [@multi_public_market], market_types: [MarketType.find_by!(code: 'works')])
  @insee_attribute = create(:market_attribute, :from_api, api_name: 'insee', category_key: 'identite_entreprise',
    subcategory_key: 'identite_entreprise_general', public_markets: [@multi_public_market])
end

Given('the candidate declared only the services lot') do
  @market_application.lots = [@lot_services1]
end

Given('the candidate declared the works and services lots') do
  @market_application.lots = [@lot_works1, @lot_services1]
end

Given('the APIs of the services lot have been fetched') do
  @market_application.update!(api_fetch_status: { 'insee' => { 'status' => 'completed', 'fields_filled' => 1 } })
end

Given('API fetches are queued without being run') do
  ActiveJob::Base.queue_adapter = :test
end

Given('the candidate uploaded {string} as Qualibat certificate') do |filename|
  response = MarketAttributeResponse.build_for_attribute(@qualibat_attribute, market_application: @market_application)
  response.documents.attach(io: StringIO.new('PDF'), filename:, content_type: 'application/pdf')
  response.save!
end

When('the candidate adds the works lot to the declared lots') do
  visit lot_selection_candidate_market_application_path(@market_application.identifier, edit: 1)
  check 'Lot 1 - Gros œuvre'
  find('button[type="submit"][form="lot-selection-form"]').click
end

When('the candidate keeps only the services lot') do
  visit lot_selection_candidate_market_application_path(@market_application.identifier, edit: 1)
  uncheck 'Lot 1 - Gros œuvre'
  find('button[type="submit"][form="lot-selection-form"]').click
end

When('the candidate visits the API data recovery step') do
  visit step_candidate_market_application_path(@market_application.identifier, :api_data_recovery_status)
end

When('the candidate visits the summary step') do
  visit step_candidate_market_application_path(@market_application.identifier, :summary)
end

Then('only the Qualibat API should be queued for fetching') do
  coordinator_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
    job['job_class'] == 'FetchApiDataCoordinatorJob'
  end

  expect(coordinator_jobs.pluck('arguments')).to eq([[@market_application.id, ['qualibat']]])
end

Then('the Qualibat API should be pending') do
  statuses = @market_application.reload.api_fetch_status.transform_values { |status| status['status'] }

  expect(statuses).to eq('insee' => 'completed', 'qualibat' => 'pending')
end

Then('the candidate should not see {string} on the summary') do |filename|
  expect(page).to have_content(I18n.t('candidate.market_applications.summary.title'))
  expect(page).to have_no_content(filename)
end
