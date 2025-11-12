# frozen_string_literal: true

class Qualifelec::DownloadDocument < DownloadDocument
  protected

  def document_url_key
    :documents
  end

  def generate_filename(_uri, index)
    siret = context.params[:siret]
    siren = siret[0..8]
    "certificat_qualifelec_#{siren}_#{index}.jpg"
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

    downloaded_files = document_urls.each_with_index.map do |url, index|
      download_single_document(url, index + 1)
    end

    store_documents(downloaded_files)
  rescue StandardError => e
    context.fail!(error: "Failed to download document: #{e.message}")
  end

  def download_single_document(url, index)
    uri = URI(url)
    response = perform_http_request(uri)
    validate_image_content!(response.body)
    build_document_hash(response, uri, index)
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
    :documents
  end

  def validate_image_content!(body)
    raise "Downloaded file is too small (#{body.bytesize} bytes)" if body.blank? || body.bytesize < 100

    binary_body = body.dup.force_encoding('ASCII-8BIT')
    jpeg_header = "\xFF\xD8\xFF".dup.force_encoding('ASCII-8BIT')
    png_header = "\x89PNG".dup.force_encoding('ASCII-8BIT')

    return if binary_body.start_with?(jpeg_header, png_header)

    raise 'Downloaded file is not a valid image (missing valid image header)'
  end
end
