# frozen_string_literal: true

require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.before(:each) do
    WebMock.enable!
  end

  config.after(:each) do
    WebMock.reset!
  end
end
