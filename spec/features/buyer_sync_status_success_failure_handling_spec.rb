# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.feature 'Buyer sync: Success & Failure Handling', type: :feature do
  include ActiveJob::TestHelper

  let(:editor) do
    create(:editor,
      completion_webhook_url: 'https://editor.example.com/webhook')
  end
  let(:public_market) { create(:public_market, :completed, editor:, sync_status: 'sync_processing') }

  before do
    WebMock.enable!
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    WebMock.disable!
    WebMock.reset!
  end

  scenario 'Successful webhook sync with auto-redirect' do
    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 200, body: 'OK')

    visit buyer_sync_status_path(public_market.identifier)

    expect(page).to have_content('Synchronisation en cours')

    perform_enqueued_jobs do
      PublicMarketWebhookJob.perform_later(public_market.id)
    end

    visit buyer_sync_status_path(public_market.identifier)
    expect(page).to have_content('Synchronisation réussie')
    expect(page).to have_content('Nous avons transmis automatiquement la configuration à votre profil acheteur')
  end

  scenario 'Failed webhook with proper error handling' do
    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 404, body: 'Not Found')

    allow(BugTrackerService).to receive(:capture_exception)

    visit buyer_sync_status_path(public_market.identifier)

    PublicMarketWebhookJob.perform_now(public_market.id)

    public_market.reload
    expect(public_market.sync_status).to eq('sync_failed')

    visit buyer_sync_status_path(public_market.identifier)
    expect(page).to have_content('Erreur inattendue')
  end

  scenario 'Admin can manually retry failed webhooks' do
    public_market.update!(sync_status: 'sync_failed')

    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 200, body: 'OK')

    perform_enqueued_jobs do
      PublicMarketWebhookJob.perform_later(public_market.id)
    end

    public_market.reload
    expect(public_market.sync_status).to eq('sync_completed')
  end

  scenario 'Sync status polling works' do
    visit buyer_sync_status_path(public_market.identifier)

    expect(page).to have_css('[data-controller="sync-status"]')
    expect(page).to have_css('[data-sync-status-url-value]')
  end
end
