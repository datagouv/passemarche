# frozen_string_literal: true

class Cibtp < ApplicationOrganizer
  organize Cibtp::MakeRequest,
    Cibtp::BuildResource,
    Cibtp::DownloadDocument

  def self.call(context = {})
    context[:api_name] ||= 'cibtp'
    super
  end
end
