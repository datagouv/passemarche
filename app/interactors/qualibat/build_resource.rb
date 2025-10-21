class Qualibat::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      document_url:
    }
  end

  private

  def document_url
    json_body.dig('certificat_batiment', 'document_url')
  end
end
