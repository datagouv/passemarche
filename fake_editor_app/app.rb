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

    return render_dashboard_with_error("Token d'accès non valide. Veuillez vous authentifier d'abord.", current_token) unless current_token&.valid?

    market_data = extract_market_data_from_params
    validation_error = validate_market_data(market_data)

    return render_dashboard_with_error(validation_error, current_token) if validation_error

    api_response = @fast_track_client.create_public_market(current_token.access_token, market_data)
    render_dashboard_with_success(api_response, current_token)
  rescue StandardError => e
    handle_market_creation_error(e)
  end

  private

  def extract_market_data_from_params
    {
      name: params[:name],
      lot_name: params[:lot_name] && params[:lot_name].empty? ? nil : params[:lot_name],
      deadline: params[:deadline],
      market_type: params[:market_type]
    }
  end

  def validate_market_data(market_data)
    required_fields = %i[name deadline market_type]
    missing_fields = required_fields.select { |field| market_data[field].to_s.strip.empty? }

    return nil if missing_fields.empty?

    'Veuillez remplir tous les champs obligatoires (nom du marché, date limite, typologie).'
  end

  def render_dashboard_with_error(error_message, token = nil)
    @error = error_message
    @current_token = token
    erb :dashboard
  end

  def render_dashboard_with_success(api_response, token)
    @success = "Marché créé avec succès! Identifiant: #{api_response['identifier']}"
    @configuration_url = api_response['configuration_url']
    @current_token = token
    erb :dashboard
  end

  def handle_market_creation_error(error)
    @error = "Erreur lors de la création du marché: #{error.message}"
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    erb :dashboard
  end
end
