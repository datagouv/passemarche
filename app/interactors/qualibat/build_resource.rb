class Qualibat::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      document_url:
    }
  end

  private

  def document_url
    json_body['document_url']
  end
end
