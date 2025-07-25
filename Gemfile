# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.4.5'

gem 'bootsnap', require: false
gem 'doorkeeper', '~> 5.7'
gem 'importmap-rails'
gem 'jbuilder'
gem 'kamal', require: false
gem 'pg', '>= 1.1'
gem 'propshaft'
gem 'puma', '>= 5.0'
gem 'rails', '~> 8.0.2'
gem 'solid_cable'
gem 'solid_cache'
gem 'solid_queue'
gem 'stimulus-rails'
gem 'thruster', require: false
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[windows jruby]
gem 'wicked'

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'rspec-rails', '~> 8.0'
  gem 'rubocop-rails-omakase', require: false
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'cucumber-rails', '~> 3.1', require: false
  gem 'database_cleaner-active_record', '~> 2.2'
  gem 'selenium-webdriver'
  gem 'shoulda-matchers', '~> 6.4'
end
