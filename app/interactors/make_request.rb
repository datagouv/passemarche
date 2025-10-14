# frozen_string_literal: true

class MakeRequest < ApplicationInteractor
  def call
    api_call_with_error_handing
    check_response_status
  end

  protected

  def request_uri
    @request_uri ||= URI("#{Rails.application.credentials.api_entreprise.base_url}#{endpoint_url}")
  end

  def endpoint_url
    raise NotImplementedError
  end

  def request_body
    nil
  end

  def http_options
    {
      use_ssl: request_uri.scheme == 'https',
      read_timeout: 30,
      open_timeout: 10
    }
  end

  def extra_http_start_options
    {}
  end

  def extra_headers(request)
    request['Authorization'] = "Bearer #{Rails.application.credentials.api_entreprise.token}"
    request['Content-Type'] = 'application/json'
  end

  def request_params
    {
      context: request_context,
      recipient: request_recipient,
      object: request_object
    }
  end

  def request_context
    'Candidature marché public'
  end

  def request_recipient
    '13002526500013'
  end

  def request_object
    if context.market_application
      "Réponse marché: #{context.market_application.public_market.name}"
    else
      'Réponse appel offre'
    end
  end

  private

  def api_call_with_error_handing
    api_call
  rescue Net::OpenTimeout, Net::ReadTimeout, EOFError => e
    context.fail!(error: "Timeout: #{e.message}")
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ENETUNREACH => e
    context.fail!(error: "Connection error: #{e.message}")
  rescue OpenSSL::SSL::SSLError => e
    context.fail!(error: "SSL error: #{e.message}")
  rescue SocketError => e
    context.fail!(error: "Socket error: #{e.message}")
  end

  def http_wrapper(&)
    Net::HTTP.start(request_uri.host, request_uri.port, http_options.merge(extra_http_start_options)) do |http|
      request = yield

      extra_headers(request)
      http.request(request)
    end
  end

  def api_call
    context.response = http_wrapper do
      Net::HTTP::Get.new(build_request).tap do |req|
        req.body = request_body
      end
    end
  end

  def build_request
    request_uri.tap do |uri|
      uri.query = encode_request_params if query_params?
    end
  end

  def encode_request_params
    URI.encode_www_form(request_params)
  end

  def query_params?
    !request_params.nil? &&
      request_params.any?
  end

  def check_response_status
    return if context.response.is_a?(Net::HTTPSuccess)

    error_message = extract_error_message || "HTTP #{context.response.code}: #{context.response.message}"
    context.fail!(error: error_message)
  end

  def extract_error_message
    return nil unless context.response.body

    parsed = JSON.parse(context.response.body)
    error = parsed.dig('errors', 0)
    return nil unless error

    "#{error['title']}: #{error['detail']}" if error['title'] && error['detail']
  rescue JSON::ParserError
    nil
  end
end
