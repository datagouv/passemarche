# frozen_string_literal: true

require 'sequel'
require 'fileutils'

# Initialize database connection with proper path resolution
db_dir = File.expand_path('..', __dir__)
db_path = ENV['DB_PATH'] || File.join(db_dir, 'fake_editor.db')

# Initialize SQLite connection
DB = Sequel.sqlite(db_path)

# Configure Sequel to use UTC and not try to use Rails time zone methods
Sequel.datetime_class = DateTime
Sequel.application_timezone = :utc
Sequel.database_timezone = :utc

# Create tables if they don't exist
DB.create_table?(:tokens) do
  primary_key :id
  String :access_token, null: false
  Integer :expires_in, null: false
  String :token_type, null: false
  String :scope
  DateTime :created_at, null: false
  DateTime :expires_at, null: false
end

class Token < Sequel::Model(DB[:tokens])
  def self.current_token
    where { expires_at > DateTime.now }.order(:created_at).last
  end

  def self.store_token(access_token:, expires_in:, token_type:, scope:)
    # Clear old tokens
    clear_tokens

    # Store new token
    create(
      access_token: access_token,
      expires_in: expires_in,
      token_type: token_type,
      scope: scope,
      created_at: DateTime.now,
      expires_at: DateTime.now + Rational(expires_in.to_i, 86_400)
    )
  end

  def self.clear_tokens
    dataset.delete
  end

  def expired?
    expires_at < DateTime.now
  end

  def valid?
    !expired?
  end

  def time_until_expiry
    return 0 if expired?

    ((expires_at - DateTime.now) * 86_400).to_i
  end
end
