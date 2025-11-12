# frozen_string_literal: true

class Qualifelec < ApplicationOrganizer
  organize Qualifelec::MakeRequest,
    Qualifelec::BuildResource,
    Qualifelec::DownloadDocument,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'qualifelec'
    super
  end
end
