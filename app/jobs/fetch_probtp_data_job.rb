# frozen_string_literal: true

class FetchProbtpDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'probtp'
  end

  def self.api_service
    Probtp
  end
end
