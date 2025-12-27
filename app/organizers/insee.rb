class Insee < ApplicationOrganizer
  organize Insee::MakeRequest,
    Insee::BuildResource,
    Insee::MapInseeApiData

  def self.call(context = {})
    context[:api_name] ||= 'insee'
    super
  end
end
