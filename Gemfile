# frozen_string_literal: true


# Source for Ruby gems
source 'https://rubygems.org'


# Ruby version
ruby '3.4.5'


# Core Rails and dependencies
gem 'rails', '~> 8.1.1'           # Main Rails framework
gem 'pg', '>= 1.1'                # PostgreSQL adapter
gem 'puma', '>= 5.0'              # Web server
gem 'jbuilder'                    # JSON responses
gem 'propshaft'                   # Asset pipeline
gem 'view_component'              # Component-based views
gem 'importmap-rails'             # JS import maps
gem 'stimulus-rails'              # Stimulus JS integration
gem 'turbo-rails'                 # Turbo Streams/Frames
gem 'bootsnap', require: false    # Speeds up boot time
gem 'tzinfo-data', platforms: %i[windows jruby] # Timezone data for Windows/JRuby

# Authentication & API
gem 'devise'                      # User authentication
gem 'doorkeeper', '~> 5.7'        # OAuth2 provider

# Business logic
gem 'interactor', '~> 3.2'        # Service objects (Interactors)
gem 'mission_control-jobs'        # Background jobs
gem 'solid_queue'                 # Job queue
gem 'solid_cache'                 # Caching
gem 'solid_cable'                 # ActionCable alternative
gem 'thruster', require: false    # Job orchestration
gem 'kamal', require: false       # Deployment (Kamal)

# Utilities
gem 'csv'                        # CSV parsing
gem 'faraday', '~> 2.14'         # HTTP client
gem 'rubyzip', '~> 3.2'          # ZIP file support
gem 'wicked'                     # Wizard-style workflows
gem 'wicked_pdf'                 # PDF generation

# Error tracking
gem 'sentry-rails'               # Sentry integration
gem 'sentry-ruby'                # Sentry core


# Development, test, and sandbox tools
group :development, :test, :sandbox do
  gem 'lookbook'                  # ViewComponent preview UI
end


group :development, :test do
  gem 'debug', platforms: %i[mri windows]      # Debugging
  gem 'factory_bot_rails', '~> 6.5'           # Test factories
  gem 'pry'                                   # REPL
  gem 'pry-byebug'                            # Debugging in Pry
  gem 'pry-rails'                             # Pry integration for Rails
  gem 'rspec-rails', '~> 8.0'                 # RSpec testing
  gem 'rubocop-rails-omakase', require: false # Rubocop config
  gem 'wkhtmltopdf-binary'                    # PDF binary for WickedPDF
end


group :development do
  gem 'web-console'                           # Rails console in browser
end


group :test do
  gem 'capybara'                              # Integration testing
  gem 'cucumber-rails', '~> 4.0', require: false # Cucumber BDD
  gem 'database_cleaner-active_record', '~> 2.2' # Test DB cleaning
  gem 'selenium-webdriver'                    # Browser automation
  gem 'shoulda-matchers', '~> 7.0'            # RSpec matchers
  gem 'webmock', '~> 3.26'                    # HTTP request stubbing
end
