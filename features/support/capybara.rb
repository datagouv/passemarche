# frozen_string_literal: true

require 'selenium-webdriver'

Capybara.register_driver :headless_chromium do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = '/usr/bin/chromium-browser'
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--disable-blink-features=AutomationControlled')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.javascript_driver = :headless_chromium
Capybara.default_max_wait_time = 10
Capybara.server = :puma, { Silent: true }
