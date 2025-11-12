# frozen_string_literal: true

class Opqibi < ApplicationOrganizer
  organize Opqibi::MakeRequest,
    Opqibi::BuildResource,
    MapApiData

  def self.call(context = {})
    context[:api_name] ||= 'opqibi'
    super
  end
end
