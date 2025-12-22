# frozen_string_literal: true

class Bodacc < ApplicationOrganizer
  organize Bodacc::MakeRequest,
    Bodacc::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'bodacc'
    super
  end
end
