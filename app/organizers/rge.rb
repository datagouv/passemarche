# frozen_string_literal: true

class Rge < ApplicationOrganizer
  organize Rge::MakeRequest,
    Rge::BuildResource,
    Rge::DownloadDocument,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'rge'
    super
  end
end
