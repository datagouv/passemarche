# frozen_string_literal: true

class Rne < ApplicationOrganizer
  organize Rne::MakeRequest,
    Rne::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'rne'
    super
  end
end
