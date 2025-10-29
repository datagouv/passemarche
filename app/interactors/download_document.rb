# frozen_string_literal: true

class DownloadDocument < ApplicationInteractor
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
      context.bundled_data.data.public_send(document_url_key)
    rescue NoMethodError
      nil
    end

    return if url.present?

    context.fail!(error: "Missing #{document_url_key} in response")
  end

  def download_and_store_document
    url = context.bundled_data.data.public_send(document_url_key)
    uri = URI(url)
    downloaded_file = download_file_from_uri(uri)

    context.bundled_data.data.deep_merge!(
      storage_key => downloaded_file
    )
  rescue StandardError => e
    context.fail!(error: "Failed to download document: #{e.message}")
  end

  def storage_key
    document_url_key.to_s.gsub(/_url$/, '').to_sym
  end

  def download_file_from_uri(uri)
    http_options = {
      use_ssl: uri.scheme == 'https',
      read_timeout: 60,
      open_timeout: 30
    }

    response = Net::HTTP.start(uri.host, uri.port, http_options) do |http|
      request = Net::HTTP::Get.new(uri)
      add_request_headers(request)
      http.request(request)
    end

    raise "HTTP #{response.code}: #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    {
      io: StringIO.new(response.body),
      filename: extract_filename(response, uri),
      content_type: extract_content_type(response),
      metadata: document_metadata
    }
  end

  def add_request_headers(request)
    token = Rails.application.credentials.api_entreprise&.token
    request['Authorization'] = "Bearer #{token}" if token.present?
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
end
