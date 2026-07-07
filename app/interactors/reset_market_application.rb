# frozen_string_literal: true

class ResetMarketApplication < ApplicationInteractor
  delegate :market_application, to: :context

  def call
    ActiveRecord::Base.transaction do
      purge_api_responses
      purge_generated_attachments
      reset_application_state
    end
  end

  private

  def purge_api_responses
    market_application.market_attribute_responses.where(source: :auto).find_each(&:reset_api_data!)
  end

  def purge_generated_attachments
    %i[attestation buyer_attestation documents_package].each do |attachment|
      market_application.public_send(attachment).purge_later if market_application.public_send(attachment).attached?
    end
  end

  def reset_application_state
    market_application.update!(
      completed_at: nil,
      sync_status: :sync_pending,
      api_fetch_status: {},
      attests_no_exclusion_motifs: false
    )
  end
end
