# frozen_string_literal: true

class FetchOpqibiDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'opqibi'
  end

  def self.api_service
    Opqibi
  end
end
