# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.feature 'Buyer sync: Success & Failure Handling', type: :feature do
  include ActiveJob::TestHelper

  let(:editor) do
    create(:editor,
      completion_webhook_url: 'https://editor.example.com/webhook')
  end
  let(:public_market) { create(:public_market, :completed, editor: editor, sync_status: 'sync_processing') }

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
      WebhookSyncJob.perform_later(public_market.id)
    end

    visit buyer_sync_status_path(public_market.identifier)
    expect(page).to have_content('Synchronisation réussie')
    expect(page).to have_content('Votre marché a été synchronisé avec succès')
  end

  scenario 'Failed webhook with proper error handling' do
    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 500, body: 'Internal Server Error')
      .times(3)

    visit buyer_sync_status_path(public_market.identifier)

    # Run the job directly which will fail and set status
    begin
      WebhookSyncJob.perform_now(public_market.id)
    rescue RuntimeError
      # Expected to fail due to webhook error
    end

    public_market.reload
    expect(public_market.sync_status).to eq('sync_failed')

    visit buyer_sync_status_path(public_market.identifier)
    expect(page).to have_content('Erreur inattendue')
  end

  scenario 'Admin can manually retry failed webhooks' do
    public_market.update!(sync_status: 'sync_failed')

    stub_request(:post, editor.completion_webhook_url)
      .to_return(status: 200, body: 'OK')

    # Re-run the sync job to retry
    perform_enqueued_jobs do
      WebhookSyncJob.perform_later(public_market.id)
    end

    # Public market should be marked as completed
    public_market.reload
    expect(public_market.sync_status).to eq('sync_completed')
  end

  scenario 'Sync status polling works' do
    visit buyer_sync_status_path(public_market.identifier)

    expect(page).to have_css('[data-controller="sync-status"]')
    expect(page).to have_css('[data-sync-status-url-value]')
  end
end
