# frozen_string_literal: true

class ActesBilans::DownloadDocument < DownloadDocument
  include SiretHelpers

  protected

  def document_url_key
    :actes_et_bilans
  end

  def generate_filename(_uri, index)
    "bilan_#{siren}_#{index}.pdf"
  end

  private

  def validate_context
    if context.bundled_data.blank?
      context.fail!(error: 'Missing bundled_data')
      return
    end

    urls = begin
      bundled_data.public_send(document_url_key)
    rescue NoMethodError
      nil
    end

    return if urls.is_a?(Array)

    context.fail!(error: "Missing #{document_url_key} in response")
  end

  def download_and_store_document
    document_urls = bundled_data.public_send(document_url_key)

    return store_documents([]) if document_urls.empty?

    downloaded_files = document_urls.each_with_index.filter_map do |url, index|
      download_single_document(url, index + 1)
    end

    if downloaded_files.empty?
      context.fail!(error: 'Failed to download any documents')
    else
      store_documents(downloaded_files)
    end
  end

  def download_single_document(url, index)
    uri = URI(url)
    response = perform_http_request(uri)
    validate_pdf_content!(response.body)
    build_document_hash(response, uri, index)
  rescue StandardError => e
    Rails.logger.warn("Failed to download document from #{url}: #{e.message}")
    nil
  end

  def build_document_hash(response, uri, index)
    {
      io: StringIO.new(response.body),
      filename: generate_filename(uri, index),
      content_type: extract_content_type(response),
      metadata: document_metadata
    }
  end

  def store_documents(downloaded_files)
    bundled_data.deep_merge!(
      storage_key => downloaded_files
    )
  end

  def storage_key
    :actes_et_bilans
  end
end
