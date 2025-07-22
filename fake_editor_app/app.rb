# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/json'
require 'dotenv/load'
require 'sqlite3'
require_relative 'lib/database'
require_relative 'lib/fast_track_client'

class FakeEditorApp < Sinatra::Base
  configure do
    set :views, File.join(File.dirname(__FILE__), 'views')
    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :show_exceptions, development?
  end

  before do
    # Initialize Fast Track client
    @fast_track_client = FastTrackClient.new(
      ENV.fetch('CLIENT_ID', nil),
      ENV.fetch('CLIENT_SECRET', nil),
      ENV.fetch('FAST_TRACK_URL', nil)
    )
  end

  get '/' do
    @current_token = Token.current_token
    erb :dashboard
  end

  post '/authenticate' do
    token_data = @fast_track_client.authenticate

    # Store token in database
    Token.store_token(
      access_token: token_data['access_token'],
      expires_in: token_data['expires_in'],
      token_type: token_data['token_type'],
      scope: token_data['scope']
    )

    redirect '/'
  rescue SQLite3::ReadOnlyException => e
    @error = "Database error: #{e.message}. Check file permissions."
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    erb :dashboard
  rescue StandardError => e
    @error = "Authentication failed: #{e.message}"
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    erb :dashboard
  end

  post '/refresh' do
    token_data = @fast_track_client.authenticate

    # Update token in database
    Token.store_token(
      access_token: token_data['access_token'],
      expires_in: token_data['expires_in'],
      token_type: token_data['token_type'],
      scope: token_data['scope']
    )

    redirect '/'
  rescue StandardError => e
    @error = "Token refresh failed: #{e.message}"
    erb :dashboard
  end

  get '/clear' do
    Token.clear_tokens
    redirect '/'
  rescue SQLite3::ReadOnlyException => e
    @error = "Database error: #{e.message}. Check file permissions."
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    erb :dashboard
  rescue StandardError => e
    @error = "Clear tokens failed: #{e.message}"
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    erb :dashboard
  end

  post '/create_market' do
    current_token = Token.current_token

    unless current_token&.valid?
      @error = "Token d'accès non valide. Veuillez vous authentifier d'abord."
      @current_token = current_token
      return erb :dashboard
    end

    market_data = @fast_track_client.create_public_market(current_token.access_token)

    @success = "Marché créé avec succès! Identifiant: #{market_data['identifier']}"
    @configuration_url = market_data['configuration_url']
    @current_token = current_token

    erb :dashboard
  rescue StandardError => e
    @error = "Erreur lors de la création du marché: #{e.message}"
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    erb :dashboard
  end
end
