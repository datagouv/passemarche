# frozen_string_literal: true

class Dgfip::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      document: document_url
    }
  end

  private

  def document_url
    json_body['document_url']
  end
end
