# frozen_string_literal: true

class Rge::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      documents: certificates_data
    }
  end

  private

  def certificates_data
    json_body.map do |cert_wrapper|
      cert = cert_wrapper['data']
      {
        url: cert['url'],
        nom_certificat: cert['nom_certificat'],
        domaine: cert['domaine'],
        organisme: cert['organisme'],
        date_expiration: cert['date_expiration']
      }
    end
  end

  def json_body
    @json_body ||= begin
      parsed = JSON.parse(context.response.body)
      raise KeyError unless parsed.key?('data')

      parsed['data']
    end
  end

  def valid_json?
    json_body.is_a?(Array)
  rescue JSON::ParserError, KeyError
    false
  end
end
