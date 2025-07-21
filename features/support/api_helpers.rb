# frozen_string_literal: true

module ApiHelpers
  include Rack::Test::Methods

  def app
    Rails.application
  end
end

World(ApiHelpers)
