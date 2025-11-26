# frozen_string_literal: true

class DocumentNamingService
  attr_reader :market_application

  def initialize(market_application)
    @market_application = market_application
    @filename_mapping = nil
  end

  def filename_mapping
    @filename_mapping ||= compute_filename_mapping
  end

  def system_filename_for(document)
    mapping = filename_mapping[document.blob_id]
    mapping&.dig(:system) || document.filename.to_s
  end

  def original_filename_for(document)
    document.filename.to_s
  end

  def api_document?(document)
    document.metadata['source']&.start_with?('api_') || false
  end

  private

  def compute_filename_mapping
    mapping = {}
    responses = load_file_attachable_responses

    responses.each_with_index do |response, response_index|
      next unless response.documents.attached?

      response.documents.each_with_index do |document, doc_index|
        mapping[document.blob_id] = build_mapping_entry(document, response, response_index, doc_index)
      end
    end

    mapping
  end

  def load_file_attachable_responses
    market_application.market_attribute_responses
      .with_file_attachments
      .includes(:market_attribute, documents_attachments: :blob)
      .order(:id)
  end

  def build_mapping_entry(document, response, response_index, doc_index)
    {
      original: document.filename.to_s,
      system: build_system_filename(document, response, response_index, doc_index)
    }
  end

  def build_system_filename(document, response, response_index, doc_index)
    prefix = api_document?(document) ? 'api' : 'user'
    field_key = response.market_attribute.key
    original_filename = document.filename.to_s

    "#{prefix}_#{format('%02d', response_index + 1)}_#{format('%02d', doc_index + 1)}_#{field_key}_#{original_filename}"
  end
end
