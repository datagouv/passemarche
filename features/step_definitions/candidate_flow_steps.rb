Given('a public market exists') do
  @editor = create(:editor)
  @public_market = create(:public_market, :completed, editor: @editor)
end

Given('a candidate starts a new application') do
  @market_application = create(:market_application, public_market: @public_market, siret: '73282932000074')
  visit "/candidate/market_applications/#{@market_application.identifier}/market_and_company_information"
end

When('the candidate visits the {string} step') do |step|
  visit "/candidate/market_applications/#{@market_application.identifier}/#{step}"
end

Then('they should see the {string} step') do |step|
  expect(page).to have_current_path(
    "/candidate/market_applications/#{@market_application.identifier}/#{step}",
    ignore_query: true
  )
end

When('I proceed to the summary step') do
  visit current_path.sub('technical_capacities', 'summary')
end

Then('I should see a summary of my application') do
  expect(page).to have_content('Synthèse de votre candidature')
end

When('I submit my application') do
  click_button 'Transmettre ma candidature'
end
