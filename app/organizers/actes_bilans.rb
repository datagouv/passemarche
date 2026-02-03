# frozen_string_literal: true

class ActesBilans < ApplicationOrganizer
  organize ActesBilans::MakeRequest,
    ActesBilans::BuildResource,
    ActesBilans::DownloadDocument,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'actes_bilans'
    super
  end
end
