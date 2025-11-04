# frozen_string_literal: true

class Probtp < ApplicationOrganizer
  organize Probtp::MakeRequest,
    Probtp::BuildResource,
    Probtp::DownloadDocument,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'probtp'
    super
  end
end
