# frozen_string_literal: true

When('I visit the consultation page for my application') do
  visit consultation_candidate_market_application_path(@market_application.identifier)
end

When('I visit the consultation page for the in-progress application') do
  visit consultation_candidate_market_application_path(@in_progress_application.identifier)
end

Then('I should be on the dashboard') do
  expect(page).to have_current_path(candidate_dashboard_path)
end

Given('my application has an attestation') do
  pdf_content = '%PDF-1.4 fake pdf content'
  @market_application.attestation.attach(
    io: StringIO.new(pdf_content),
    filename: 'attestation.pdf',
    content_type: 'application/pdf'
  )
end

Given('I have an in-progress application') do
  @market_application.reload
  @in_progress_application = create(:market_application,
    public_market: @public_market,
    siret: @market_application.siret,
    user: @market_application.user)
end
