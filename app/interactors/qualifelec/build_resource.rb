# frozen_string_literal: true

class Qualifelec::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      documents: document_urls
    }
  end

  def valid_json?
    json_body.is_a?(Array)
  rescue JSON::ParserError
    false
  end

  private

  def document_urls
    return [] unless json_body.is_a?(Array)

    json_body.filter_map do |certificate|
      certificate.dig('data', 'document_url')
    end
  end
end
