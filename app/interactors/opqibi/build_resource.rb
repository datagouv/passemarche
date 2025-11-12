# frozen_string_literal: true

class Opqibi::BuildResource < BuildResource
  protected

  def resource_attributes
    {
      url: certificate_url
    }
  end

  private

  def certificate_url
    json_body['url']
  end
end
