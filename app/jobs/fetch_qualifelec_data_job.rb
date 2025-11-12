# frozen_string_literal: true

class FetchQualifelecDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'qualifelec'
  end

  def self.api_service
    Qualifelec
  end
end
