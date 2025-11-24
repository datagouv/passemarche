class Urssaf < ApplicationOrganizer
  organize Urssaf::MakeRequest,
    Urssaf::BuildResource,
    Urssaf::DownloadDocument,
    Urssaf::MapUrssafApiData

  def self.call(context = {})
    context[:api_name] ||= 'urssaf_attestation_vigilance'
    super
  end
end
