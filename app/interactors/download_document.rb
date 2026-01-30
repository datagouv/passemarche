# frozen_string_literal: true

class DownloadDocument < ApplicationInteractor
  DOWNLOAD_READ_TIMEOUT = 60
  DOWNLOAD_OPEN_TIMEOUT = 30

  def call
    validate_context
    return if context.failure?

    download_and_store_document
  end

  protected

  def document_url_key
    :document_url
  end

  def generate_filename(_uri)
    "document_#{Time.current.to_i}.pdf"
  end

  def document_metadata
    {
      source: "api_#{context.api_name}",
      api_name: context.api_name,
      downloaded_at: Time.current.iso8601
    }
  end

  private

  def validate_context
    if context.bundled_data.blank?
      context.fail!(error: 'Missing bundled_data')
      return
    end

    url = begin
      bundled_data.public_send(document_url_key)
    rescue NoMethodError
      nil
    end

    return if url.present?

    context.fail!(error: "Missing #{document_url_key} in response")
  end

  def download_and_store_document
    downloaded_file = download_document
    store_document(downloaded_file)
  rescue URI::InvalidURIError,
         Net::OpenTimeout, Net::ReadTimeout, Net::HTTPError,
         SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET,
         OpenSSL::SSL::SSLError,
         IOError,
         DocumentDownloadError => e
    context.fail!(error: "Failed to download document: #{e.message}")
  end

  def download_document
    uri = URI(bundled_data.public_send(document_url_key))
    response = perform_http_request(uri)
    validate_pdf_content!(response.body)
    build_document_hash(response, uri)
  end

  def store_document(downloaded_file)
    bundled_data.deep_merge!(
      storage_key => downloaded_file
    )
  end

  def storage_key
    document_url_key.to_s.gsub(/_url$/, '').to_sym
  end

  def bundled_data
    @bundled_data ||= context.bundled_data&.data
  end

  def perform_http_request(uri)
    http_options = {
      use_ssl: uri.scheme == 'https',
      read_timeout: DOWNLOAD_READ_TIMEOUT,
      open_timeout: DOWNLOAD_OPEN_TIMEOUT
    }

    response = Net::HTTP.start(uri.host, uri.port, http_options) do |http|
      request = Net::HTTP::Get.new(uri)
      add_request_headers(request)
      http.request(request)
    end

    raise DocumentDownloadError.new("HTTP #{response.code}: #{response.message}", http_status: response.code.to_i) unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def build_document_hash(response, uri)
    {
      io: StringIO.new(response.body),
      filename: extract_filename(response, uri),
      content_type: extract_content_type(response),
      metadata: document_metadata
    }
  end

  def add_request_headers(_request)
    # Override in subclasses if authentication is needed
  end

  def extract_filename(response, uri)
    if response['content-disposition']
      match = response['content-disposition'].match(/filename="?([^"]+)"?/)
      return match[1] if match
    end

    path_filename = File.basename(uri.path)
    return path_filename if path_filename.present? && path_filename != '/'

    generate_filename(uri)
  end

  def extract_content_type(response)
    response['content-type']&.split(';')&.first || 'application/octet-stream'
  end

  def validate_pdf_content!(body)
    raise DocumentDownloadError, "Downloaded file is too small (#{body.bytesize} bytes)" if body.blank? || body.bytesize < 100

    return if valid_pdf?(body)
    return if valid_image?(body)

    raise DocumentDownloadError, 'Downloaded file is not a valid PDF or image (missing valid file header)'
  end

  def valid_pdf?(body)
    binary_body = body.dup.force_encoding('ASCII-8BIT')
    pdf_header = '%PDF-'.dup.force_encoding('ASCII-8BIT')
    binary_body.start_with?(pdf_header)
  end

  def valid_image?(body)
    binary_body = body.dup.force_encoding('ASCII-8BIT')
    jpeg_header = "\xFF\xD8\xFF".dup.force_encoding('ASCII-8BIT')
    png_header = "\x89PNG".dup.force_encoding('ASCII-8BIT')
    binary_body.start_with?(jpeg_header, png_header)
  end
end
