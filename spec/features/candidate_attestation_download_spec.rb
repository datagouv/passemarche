# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Candidate attestation download', type: :feature do
  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end
  let(:market_application) { create(:market_application, siret: nil) }

  scenario 'completing application generates attestation and shows secure download link' do
    CompleteMarketApplication.call(market_application:)

    market_application.update!(sync_status: :sync_completed)

    visit candidate_sync_status_path(market_application.identifier)

    market_application.reload
    expect(market_application.attestation).to be_attached

    expect(page).to have_button('Télécharger mon attestation de candidature')

    download_button = find_button('Télécharger mon attestation de candidature')
    onclick_attribute = download_button[:onclick]
    expect(onclick_attribute).to include('/rails/active_storage/blobs/redirect')
    expect(onclick_attribute).to include('disposition=attachment')
  end

  scenario 'attestation not available before completion' do
    visit candidate_sync_status_path(market_application.identifier)

    expect(page).not_to have_button('Télécharger mon attestation de candidature')
  end
end
