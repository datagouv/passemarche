class Insee < ApplicationOrganizer
  organize Insee::MakeRequest,
    Insee::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'Insee'
    super
  end
end
