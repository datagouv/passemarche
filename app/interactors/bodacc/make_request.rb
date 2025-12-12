# frozen_string_literal: true

class Bodacc::MakeRequest < ApplicationInteractor
  include SiretHelpers

  BASE_URL = 'https://bodacc-datadila.opendatasoft.com/api/explore/v2.1/catalog/datasets/annonces-commerciales/records'

  def call
    make_api_call
    parse_response
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    context.fail!(error: "Timeout BODACC: #{e.message}")
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET => e
    context.fail!(error: "Erreur de connexion BODACC: #{e.message}")
  rescue OpenSSL::SSL::SSLError => e
    context.fail!(error: "Erreur SSL BODACC: #{e.message}")
  rescue JSON::ParserError => e
    context.fail!(error: "Réponse JSON invalide de BODACC: #{e.message}")
  end

  private

  def make_api_call
    uri = build_uri
    context.response = execute_http_request(uri)
    validate_response
  end

  def execute_http_request(uri)
    http_options = {
      use_ssl: uri.scheme == 'https',
      read_timeout: 30,
      open_timeout: 10
    }

    Net::HTTP.start(uri.host, uri.port, http_options) do |http|
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      response
    end
  end

  def validate_response
    return if context.response.is_a?(Net::HTTPSuccess)

    context.fail!(error: "Erreur HTTP BODACC: #{context.response.code} - #{context.response.message}")
  end

  def build_uri
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(request_params)
    uri
  end

  def parse_response
    parsed = JSON.parse(context.response.body)
    context.records = parsed['records']
  end

  def request_params
    params = {
      limit: context.rows || 50,
      offset: context.start || 0
    }

    params[:where] = "registre='#{siren}'" if siren.present?

    params
  end
end
