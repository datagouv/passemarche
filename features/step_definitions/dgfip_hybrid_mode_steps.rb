# frozen_string_literal: true

require 'webmock/cucumber'

Given('the DGFIP API will return valid chiffres d\'affaires data') do
  stub_request(:get, %r{https://staging\.entreprise\.api\.gouv\.fr/v3/dgfip/etablissements/41816609600069/chiffres_affaires\?.*})
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Authorization' => /Bearer .*/,
        'Content-Type' => 'application/json',
        'Host' => 'staging.entreprise.api.gouv.fr',
        'User-Agent' => 'Ruby'
      }
    )
    .to_return(
      status: 200,
      body: {
        data: [
          {
            data: {
              chiffre_affaires: 500_000.0,
              date_fin_exercice: '2023-12-31'
            }
          },
          {
            data: {
              chiffre_affaires: 450_000.0,
              date_fin_exercice: '2022-12-31'
            }
          },
          {
            data: {
              chiffre_affaires: 400_000.0,
              date_fin_exercice: '2021-12-31'
            }
          }
        ]
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

  FetchChiffresAffairesDataJob.perform_now(@market_application.id)
end

Then('I should see DGFIP data with badges and icons correctly displayed') do
  within '.fr-table' do
    expect(page).to have_css('.fr-badge', text: 'Récupéré automatiquement', count: 6)

    %w[year_1 year_2 year_3].each do |year|
      field = find("input[name*='#{year}_market_percentage']")
      expect(field).not_to be_readonly
      expect(field.value).to be_blank
    end
  end
end

Then('I should see empty market percentage fields that I can edit') do
  within '.fr-table' do
    %w[year_1 year_2 year_3].each do |year|
      field = find("input[name*='#{year}_market_percentage']")
      expect(field).not_to be_readonly
      expect(field.value).to be_blank
    end
  end
end

When('I fill in the market percentages:') do |table|
  table.hashes.each do |row|
    year = row['year']
    percentage = row['percentage']
    find("input[name*='#{year}_market_percentage']").set(percentage)
  end
end

Then('the data should have both API data and manual percentages') do
  market_attribute = MarketAttribute.find_by(key: 'capacite_economique_financiere_chiffre_affaires_global_annuel')
  response = @market_application.market_attribute_responses.find_by(market_attribute:)

  expect(response).to be_present
  expect(response.source).to eq('auto')

  %w[year_1 year_2 year_3].each do |year|
    year_data = response.value[year]
    expect(year_data['turnover']).to be_present # From API
    expect(year_data['fiscal_year_end']).to be_present # From API
    expect(year_data['market_percentage']).to be_present # Manually entered
  end
end
