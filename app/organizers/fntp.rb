# frozen_string_literal: true

class Fntp < ApplicationOrganizer
  organize Fntp::MakeRequest,
    Fntp::BuildResource,
    Fntp::DownloadDocument,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'fntp'
    super
  end
end
