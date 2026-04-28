# frozen_string_literal: true

module Candidate
  module WebhookSubmission
    extend ActiveSupport::Concern

    private

    def queue_webhook_and_redirect(flash_options = {})
      MarketApplicationWebhookJob.perform_later(
        @market_application.id,
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )
      redirect_to candidate_sync_status_path(@market_application.identifier), flash_options
    end
  end
end
