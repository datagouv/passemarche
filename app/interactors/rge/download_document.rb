# frozen_string_literal: true

class Rge::DownloadDocument < ApplicationInteractor
  DOWNLOAD_READ_TIMEOUT = 60
  DOWNLOAD_OPEN_TIMEOUT = 30

  def call
    validate_context
    download_all_certificates
  end

  private

  def validate_context
    if context.bundled_data.blank?
      context.fail!(error: 'Missing bundled_data')
      return
    end

    unless bundled_data.respond_to?(:documents)
      context.fail!(error: 'Missing or invalid documents array in response')
      return
    end

    certificates = bundled_data.documents
    return if certificates.is_a?(Array)

    context.fail!(error: 'Missing or invalid documents array in response')
  end

  def download_all_certificates
    certificates = bundled_data.documents

    # If API returns no certificates, that's valid - succeed with empty array
    return bundled_data.deep_merge!(documents: []) if certificates.empty?

    downloaded_documents = certificates.map.with_index do |cert, index|
      download_single_certificate(cert, index)
    end.compact

    # Fail only if API returned certificates but we couldn't download any
    if downloaded_documents.empty?
      context.fail!(error: 'Failed to download any RGE certificates')
    else
      bundled_data.deep_merge!(
        documents: downloaded_documents
      )
    end
  end

  def download_single_certificate(cert, index)
    uri = URI(cert[:url])
    response = perform_http_request(uri)
    validate_pdf_content!(response.body)
    build_document_hash(response, cert, index)
  rescue URI::InvalidURIError,
         Net::OpenTimeout, Net::ReadTimeout, Net::HTTPError,
         SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET,
         OpenSSL::SSL::SSLError,
         IOError,
         DocumentDownloadError => e
    Rails.logger.warn "Failed to download RGE certificate #{index + 1}: #{e.message}"
    nil
  end

  def perform_http_request(uri)
    http_options = {
      use_ssl: uri.scheme == 'https',
      read_timeout: DOWNLOAD_READ_TIMEOUT,
      open_timeout: DOWNLOAD_OPEN_TIMEOUT
    }

    response = Net::HTTP.start(uri.host, uri.port, http_options) do |http|
      request = Net::HTTP::Get.new(uri)
      http.request(request)
    end

    raise DocumentDownloadError.new("HTTP #{response.code}: #{response.message}", http_status: response.code.to_i) unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def build_document_hash(response, cert, index)
    {
      io: StringIO.new(response.body),
      filename: generate_filename(cert, index),
      content_type: extract_content_type(response),
      metadata: document_metadata(cert)
    }
  end

  def generate_filename(cert, index)
    siret = context.params[:siret]

    if cert[:nom_certificat].present?
      nom = cert[:nom_certificat].parameterize
      "certificat_rge_#{siret}_#{nom}.pdf"
    else
      "certificat_rge_#{siret}_#{index + 1}.pdf"
    end
  end

  def extract_content_type(response)
    response['content-type']&.split(';')&.first || 'application/pdf'
  end

  def validate_pdf_content!(body)
    raise DocumentDownloadError, "Downloaded file is too small (#{body.bytesize} bytes)" if body.blank? || body.bytesize < 100

    return if body.start_with?('%PDF-')

    raise DocumentDownloadError, 'Downloaded file is not a valid PDF (missing PDF header)'
  end

  def document_metadata(cert)
    {
      source: "api_#{context.api_name}",
      api_name: context.api_name,
      nom_certificat: cert[:nom_certificat],
      domaine: cert[:domaine],
      organisme: cert[:organisme],
      date_expiration: cert[:date_expiration],
      downloaded_at: Time.current.iso8601
    }
  end

  def bundled_data
    @bundled_data ||= context.bundled_data&.data
  end
end
