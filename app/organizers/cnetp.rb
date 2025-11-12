# frozen_string_literal: true

class Cnetp < ApplicationOrganizer
  organize Cnetp::MakeRequest,
    Cnetp::BuildResource,
    Cnetp::DownloadDocument

  def self.call(context = {})
    context[:api_name] ||= 'cnetp'
    super
  end
end
