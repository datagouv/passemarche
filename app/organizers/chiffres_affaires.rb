class ChiffresAffaires < ApplicationOrganizer
  organize Dgfip::ChiffresAffaires::MakeRequest,
    Dgfip::ChiffresAffaires::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'dgfip_chiffres_affaires'
    super
  end
end
