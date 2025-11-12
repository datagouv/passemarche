# frozen_string_literal: true

class Cibtp::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      cibtp_document: document_url
    }
  end

  private

  def document_url
    json_body['document_url']
  end
end
