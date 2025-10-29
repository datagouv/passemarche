class Dgfip < ApplicationOrganizer
  organize Dgfip::MakeRequest,
    Dgfip::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'attestations_fiscales'
    super
  end
end
