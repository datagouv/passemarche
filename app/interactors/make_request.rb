# frozen_string_literal: true

class MakeRequest < ApplicationInteractor
  def call
    api_call
  end

  protected

  def request_uri
    @request_uri ||= URI("#{Rails.application.credentials.api_entreprise.base_url}#{endpoint_url}")
  end

  def endpoint_url
    raise NotImplementedError
  end

  def request_params
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

  private

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
end
