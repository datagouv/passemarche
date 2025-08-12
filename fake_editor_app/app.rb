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
    load_markets
    @completed_market_identifier = params[:completed]
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
    
    # Store the market locally
    Market.create_from_api({
      identifier: api_response['identifier'],
      name: market_data[:name],
      lot_name: market_data[:lot_name],
      market_type_codes: market_data[:market_type_codes]
    })
    
    render_dashboard_with_success(api_response, current_token)
  rescue StandardError => e
    handle_market_creation_error(e)
  end

  post '/start_application' do
    current_token = Token.current_token
    market_identifier = params[:market_identifier]
    siret = params[:siret]

    return render_dashboard_with_error("Token d'accès non valide. Veuillez vous authentifier d'abord.", current_token) unless current_token&.valid?
    
    return render_dashboard_with_error("Identifiant de marché requis.", current_token) if market_identifier.to_s.strip.empty?
    
    # SIRET is optional - can be nil or empty
    siret = siret.to_s.strip.empty? ? nil : siret.strip

    api_response = @fast_track_client.create_market_application(current_token.access_token, market_identifier, siret)
    
    # Redirect to the application URL
    redirect api_response['application_url']
  rescue StandardError => e
    @error = "Erreur lors du démarrage de la candidature: #{e.message}"
    @current_token = current_token
    load_markets
    erb :dashboard
  end

  # Webhook endpoint to receive completion notifications
  post '/webhooks/voie-rapide' do
    payload = request.body.read
    signature = request.env['HTTP_X_WEBHOOK_SIGNATURE_SHA256']
    
    # In a real app, you'd verify the signature here
    # For demo purposes, we'll just process the webhook
    
    webhook_data = JSON.parse(payload)
    market_data = webhook_data['market']
    
    if market_data && market_data['identifier']
      market = Market.find_by_identifier(market_data['identifier'])
      if market
        market.mark_completed!(webhook_data)
        puts "✅ Webhook received: Market #{market_data['identifier']} completed"
      else
        puts "⚠️  Webhook received for unknown market: #{market_data['identifier']}"
      end
    end
    
    status 200
    'OK'
  rescue JSON::ParserError => e
    puts "❌ Invalid webhook payload: #{e.message}"
    status 400
    'Bad Request'
  rescue StandardError => e
    puts "❌ Webhook processing error: #{e.message}"
    status 500
    'Internal Server Error'
  end

  private

  def load_markets
    @markets = Market.order(:created_at).reverse
  end

  def extract_market_data_from_params
    market_type_codes_array = Array(params[:market_type_codes]).compact

    {
      name: params[:name],
      lot_name: params[:lot_name] && params[:lot_name].empty? ? nil : params[:lot_name],
      deadline: params[:deadline],
      market_type_codes: market_type_codes_array
    }
  end

  def validate_market_data(market_data)
    return 'Veuillez remplir le nom du marché.' if market_data[:name].to_s.strip.empty?
    return 'Veuillez remplir la date limite.' if market_data[:deadline].to_s.strip.empty?
    return 'Veuillez sélectionner une typologie.' if market_data[:market_type_codes].nil? || market_data[:market_type_codes].empty?

    nil
  end

  def render_dashboard_with_error(error_message, token = nil)
    @error = error_message
    @current_token = token
    load_markets
    erb :dashboard
  end

  def render_dashboard_with_success(api_response, token)
    @success = "Marché créé avec succès! Identifiant: #{api_response['identifier']}"
    @configuration_url = api_response['configuration_url']
    @current_token = token
    load_markets
    erb :dashboard
  end

  def handle_market_creation_error(error)
    @error = "Erreur lors de la création du marché: #{error.message}"
    @current_token = begin
      Token.current_token
    rescue StandardError
      nil
    end
    load_markets
    erb :dashboard
  end
end
