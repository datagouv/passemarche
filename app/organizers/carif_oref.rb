# frozen_string_literal: true

class CarifOref < ApplicationOrganizer
  organize CarifOref::MakeRequest,
    CarifOref::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'carif_oref'
    super
  end
end
