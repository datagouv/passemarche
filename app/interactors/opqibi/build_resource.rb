# frozen_string_literal: true

class Opqibi::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      url: certificate_url,
      date_delivrance_certificat: json_body['date_delivrance_certificat'],
      duree_validite_certificat: json_body['duree_validite_certificat']
    }
  end

  private

  def certificate_url
    json_body['url']
  end
end
