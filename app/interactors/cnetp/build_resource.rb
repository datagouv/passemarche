# frozen_string_literal: true

class Cnetp::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      cnetp_document: document_url
    }
  end

  private

  def document_url
    json_body['document_url']
  end
end
