class Qualibat < ApplicationOrganizer
  organize Qualibat::MakeRequest,
    Qualibat::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'qualibat'
    super
  end
end
