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

DB.create_table?(:markets) do
  primary_key :id
  String :identifier, null: false, unique: true
  String :name, null: false
  String :lot_name
  String :status, default: 'created'
  DateTime :completed_at
  Text :market_data
  Text :webhook_payload
  DateTime :webhook_received_at
  DateTime :created_at, null: false
end

DB.create_table?(:market_applications) do
  primary_key :id
  String :identifier, null: false, unique: true
  String :market_identifier, null: false
  String :siret
  String :status, default: 'created'
  DateTime :completed_at
  Text :application_data
  Text :webhook_payload
  DateTime :webhook_received_at
  DateTime :created_at, null: false
  
  index :market_identifier
end

# Add missing columns for existing databases
begin
  unless DB.schema(:markets).any? { |col| col[0] == :webhook_payload }
    DB.alter_table(:markets) do
      add_column :webhook_payload, String, text: true
      add_column :webhook_received_at, DateTime
    end
    puts "✅ Added webhook columns to markets table"
  end
rescue Sequel::DatabaseError => e
  # Column might already exist or other error - continue
  puts "ℹ️  Markets webhook columns: #{e.message}"
end

begin
  unless DB.schema(:market_applications).any? { |col| col[0] == :webhook_payload }
    DB.alter_table(:market_applications) do
      add_column :webhook_payload, String, text: true
      add_column :webhook_received_at, DateTime
    end
    puts "✅ Added webhook columns to market_applications table"
  end
rescue Sequel::DatabaseError => e
  # Column might already exist or other error - continue
  puts "ℹ️  Market applications webhook columns: #{e.message}"
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

class Market < Sequel::Model(DB[:markets])
  def self.create_from_api(market_data)
    create(
      identifier: market_data[:identifier] || "VR-#{Time.now.to_i}",
      name: market_data[:name],
      lot_name: market_data[:lot_name],
      status: 'created',
      market_data: market_data.to_json,
      created_at: DateTime.now
    )
  end

  def self.find_by_identifier(identifier)
    where(identifier: identifier).first
  end

  def mark_completed!(webhook_data = nil)
    update(
      status: 'completed',
      completed_at: DateTime.now,
      market_data: webhook_data ? webhook_data.to_json : market_data,
      webhook_payload: webhook_data ? webhook_data.to_json : webhook_payload,
      webhook_received_at: DateTime.now
    )
  end

  def store_webhook_payload!(webhook_data)
    update(
      webhook_payload: webhook_data.to_json,
      webhook_received_at: DateTime.now
    )
  end

  def webhook_data
    return {} if webhook_payload.nil?
    JSON.parse(webhook_payload)
  rescue JSON::ParserError
    {}
  end

  def has_webhook_data?
    respond_to?(:webhook_payload) && !webhook_payload.nil? && !webhook_payload.empty?
  end

  def applications
    MarketApplication.for_market(identifier)
  end
  
  def applications_count
    MarketApplication.where(market_identifier: identifier).count
  end
  
  def completed_applications_count
    MarketApplication.where(market_identifier: identifier, status: 'completed').count
  end

  def data
    return {} if market_data.nil?
    JSON.parse(market_data)
  rescue JSON::ParserError
    {}
  end

  def configuration_url
    return nil unless ENV['FAST_TRACK_URL']
    "#{ENV['FAST_TRACK_URL']}/buyer/public_markets/#{identifier}/setup"
  end

  # User-friendly display methods
  def status_label
    case status
    when 'created' then 'En attente de configuration'
    when 'completed' then 'Prêt pour candidatures'
    else status
    end
  end

  def status_icon
    case status
    when 'created' then '⏳'
    when 'completed' then '✅'
    else '❓'
    end
  end

  def status_color
    case status
    when 'created' then 'info'
    when 'completed' then 'success'
    else 'new'
    end
  end

  def completed_recently?
    completed_at && completed_at > DateTime.now - 1
  end
end

class MarketApplication < Sequel::Model(DB[:market_applications])
  def self.for_market(market_identifier)
    where(market_identifier: market_identifier).order(:created_at).reverse
  end
  
  def self.create_from_api(data)
    create(
      identifier: data[:identifier],
      market_identifier: data[:market_identifier],
      siret: data[:siret],
      status: 'created',
      created_at: DateTime.now
    )
  end
  
  def self.find_by_identifier(identifier)
    where(identifier: identifier).first
  end
  
  def mark_completed!(webhook_data = nil)
    update(
      status: 'completed',
      completed_at: DateTime.now,
      application_data: webhook_data ? webhook_data.to_json : application_data,
      webhook_payload: webhook_data ? webhook_data.to_json : webhook_payload,
      webhook_received_at: DateTime.now
    )
  end

  def store_webhook_payload!(webhook_data)
    update(
      webhook_payload: webhook_data.to_json,
      webhook_received_at: DateTime.now
    )
  end

  def webhook_data
    return {} if webhook_payload.nil?
    JSON.parse(webhook_payload)
  rescue JSON::ParserError
    {}
  end

  def has_webhook_data?
    respond_to?(:webhook_payload) && !webhook_payload.nil? && !webhook_payload.empty?
  end
  
  def attestation_url
    return nil unless has_webhook_data?
    webhook_data.dig('market_application', 'attestation_url')
  end
  
  def documents_package_url
    return nil unless has_webhook_data?
    webhook_data.dig('market_application', 'documents_package_url')
  end
  
  def data
    return {} if application_data.nil?
    JSON.parse(application_data)
  rescue JSON::ParserError
    {}
  end

  # User-friendly display methods
  def status_label
    case status
    when 'created' then 'En cours'
    when 'completed' then 'Terminée'
    else status
    end
  end

  def status_icon
    case status
    when 'created' then '⏳'
    when 'completed' then '✅'
    else '❓'
    end
  end

  def status_color
    case status
    when 'created' then 'info'
    when 'completed' then 'success'
    else 'new'
    end
  end

  def completed_recently?
    completed_at && completed_at > DateTime.now - 1
  end
end
