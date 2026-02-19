# frozen_string_literal: true

module Candidate
  class PrepareDocumentScanStatus < ApplicationInteractor
    delegate :market_application, :view_context, to: :context

    def call
      enqueue_missing_scans
      context.scan_status = {
        scans_complete: market_application.all_security_scans_complete?,
        blob_states: collect_blob_scan_states
      }
    end

    private

    def collect_blob_scan_states
      file_attribute_responses.select { |r| r.documents.attached? }.flat_map do |response|
        response.documents.map do |document|
          {
            blob_id: document.blob.id,
            badge_html: view_context.dsfr_malware_badge(document, class: 'fr-ml-1w')
          }
        end
      end
    end

    def enqueue_missing_scans
      file_attribute_responses.each(&:enqueue_document_scans)
    end

    def file_attribute_responses
      market_application.market_attribute_responses
        .select { |r| r.respond_to?(:documents) }
    end
  end
end
