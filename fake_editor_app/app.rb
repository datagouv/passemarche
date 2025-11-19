# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/json'
require 'dotenv/load'
require 'sqlite3'
require 'tzinfo'
require_relative 'lib/database'
require_relative 'lib/fast_track_client'

class FakeEditorApp < Sinatra::Base
  register Sinatra::Namespace

  configure do
    set :views, File.join(File.dirname(__FILE__), 'views')
    set :public_folder, File.join(File.dirname(__FILE__), 'public')
    set :show_exceptions, development?
  end

  helpers do
    def format_paris_time(datetime, format = '%d/%m/%Y à %H:%M:%S')
      return '-' if datetime.nil?

      # Convert UTC datetime to Europe/Paris timezone
      paris_tz = TZInfo::Timezone.get('Europe/Paris')
      paris_time = paris_tz.utc_to_local(datetime.to_time.utc)

      paris_time.strftime(format)
    end

    def relative_time(datetime)
      return '-' if datetime.nil?

      seconds = (DateTime.now - datetime) * 86_400

      case seconds
      when 0..59
        "Il y a quelques secondes"
      when 60..3599
        minutes = (seconds / 60).floor
        "Il y a #{minutes} minute#{'s' if minutes > 1}"
      when 3600..86_399
        hours = (seconds / 3600).floor
        "Il y a #{hours} heure#{'s' if hours > 1}"
      else
        days = (seconds / 86_400).floor
        "Il y a #{days} jour#{'s' if days > 1}"
      end
    end

    def current_page?(path)
      request.path_info.start_with?(path)
    end
  end

  before do
    # Initialize Fast Track client
    @fast_track_client = FastTrackClient.new(
      ENV.fetch('CLIENT_ID', nil),
      ENV.fetch('CLIENT_SECRET', nil),
      ENV.fetch('FAST_TRACK_URL', nil)
    )
  end

  # ==========================================
  # HOME - Role Selection
  # ==========================================

  get '/' do
    @total_markets = Market.count
    @total_applications = MarketApplication.count
    @completed_applications = MarketApplication.where(status: 'completed').count
    @current_token = Token.current_token
    @completed_market_identifier = params[:completed]
    erb :home
  end

  # ==========================================
  # BUYER ROUTES
  # ==========================================

  namespace '/buyer' do
    get '' do
      @current_token = Token.current_token
      @markets = Market.order(:created_at).reverse
      erb :'buyer/dashboard'
    end

    get '/markets/new' do
      @current_token = Token.current_token

      unless @current_token&.valid?
        @error = "Vous devez être authentifié pour créer un marché."
        redirect '/technical'
      end

      erb :'buyer/market_new'
    end

    post '/markets' do
      current_token = Token.current_token

      unless current_token&.valid?
        @error = "Token d'accès non valide. Veuillez vous authentifier d'abord."
        erb :'buyer/market_new'
        return
      end

      market_data = extract_market_data_from_params
      validation_error = validate_market_data(market_data)

      if validation_error
        @error = validation_error
        erb :'buyer/market_new'
        return
      end

      begin
        api_response = @fast_track_client.create_public_market(current_token.access_token, market_data)

        # Store the market locally
        market = Market.create_from_api({
          identifier: api_response['identifier'],
          name: market_data[:name],
          lot_name: market_data[:lot_name],
          market_type_codes: market_data[:market_type_codes]
        })

        @success = "Marché créé avec succès!"
        @market = market
        @configuration_url = api_response['configuration_url']
        erb :'buyer/market_created'
      rescue StandardError => e
        @error = "Erreur lors de la création du marché: #{e.message}"
        erb :'buyer/market_new'
      end
    end

    get '/markets/:identifier' do
      @market = Market.find_by_identifier(params[:identifier])

      unless @market
        @error = "Marché non trouvé"
        redirect '/buyer'
        return
      end

      @applications = @market.applications
      @current_token = Token.current_token
      @tab = params[:tab] || 'overview'
      erb :'buyer/market_detail'
    end

    get '/applications/:identifier' do
      @application = MarketApplication.find_by_identifier(params[:identifier])

      unless @application
        @error = "Candidature non trouvée"
        redirect '/buyer'
        return
      end

      @market = Market.find_by_identifier(@application.market_identifier)
      @current_token = Token.current_token
      @tab = params[:tab] || 'overview'
      erb :'buyer/application_detail'
    end
  end

  # ==========================================
  # CANDIDATE ROUTES
  # ==========================================

  namespace '/candidate' do
    get '' do
      @current_token = Token.current_token
      @markets = Market.where(status: 'completed').order(:created_at).reverse
      @my_applications = MarketApplication.order(:created_at).reverse.limit(10)
      erb :'candidate/dashboard'
    end

    get '/markets' do
      @current_token = Token.current_token
      @markets = Market.where(status: 'completed').order(:created_at).reverse
      erb :'candidate/markets_list'
    end

    get '/markets/:identifier' do
      @market = Market.find_by_identifier(params[:identifier])

      unless @market
        @error = "Marché non trouvé"
        redirect '/candidate'
        return
      end

      @current_token = Token.current_token
      @tab = params[:tab] || 'overview'
      erb :'candidate/market_show'
    end

    post '/markets/:identifier/apply' do
      current_token = Token.current_token
      market_identifier = params[:identifier]
      siret = params[:siret]

      unless current_token&.valid?
        @error = "Token d'accès non valide. Veuillez vous authentifier d'abord."
        @market = Market.find_by_identifier(market_identifier)
        erb :'candidate/market_show'
        return
      end

      # SIRET is optional - can be nil or empty
      siret = siret.to_s.strip.empty? ? nil : siret.strip

      begin
        api_response = @fast_track_client.create_market_application(current_token.access_token, market_identifier, siret)

        # Store the application locally
        MarketApplication.create_from_api({
          identifier: api_response['identifier'],
          market_identifier: market_identifier,
          siret: siret
        })

        # Redirect to the application URL in Voie Rapide
        redirect api_response['application_url']
      rescue StandardError => e
        @error = "Erreur lors du démarrage de la candidature: #{e.message}"
        @market = Market.find_by_identifier(market_identifier)
        @current_token = current_token
        erb :'candidate/market_show'
      end
    end

    get '/applications/:identifier' do
      @application = MarketApplication.find_by_identifier(params[:identifier])

      unless @application
        @error = "Candidature non trouvée"
        redirect '/candidate'
        return
      end

      @market = Market.find_by_identifier(@application.market_identifier)
      @current_token = Token.current_token
      @tab = params[:tab] || 'overview'
      erb :'candidate/application_detail'
    end

    get '/applications/:identifier/download_attestation' do
      @application = MarketApplication.find_by_identifier(params[:identifier])

      unless @application
        halt 404, "Candidature non trouvée"
      end

      unless @application.status == 'completed'
        halt 400, "La candidature n'est pas terminée"
      end

      unless @application.attestation_url
        halt 404, "URL d'attestation non disponible"
      end

      current_token = Token.current_token
      unless current_token&.valid?
        halt 401, "Token d'accès non valide. Veuillez vous authentifier d'abord."
      end

      begin
        pdf_content = @fast_track_client.download_attestation(current_token.access_token, @application.identifier)

        content_type 'application/pdf'
        attachment "attestation_FT#{@application.identifier}.pdf"
        pdf_content
      rescue StandardError => e
        halt 500, "Erreur lors du téléchargement: #{e.message}"
      end
    end

    get '/applications/:identifier/download_documents_package' do
      @application = MarketApplication.find_by_identifier(params[:identifier])

      unless @application
        halt 404, "Candidature non trouvée"
      end

      unless @application.status == 'completed'
        halt 400, "La candidature n'est pas terminée"
      end

      unless @application.documents_package_url
        halt 404, "URL du package de documents non disponible"
      end

      current_token = Token.current_token
      unless current_token&.valid?
        halt 401, "Token d'accès non valide. Veuillez vous authentifier d'abord."
      end

      begin
        zip_content = @fast_track_client.download_documents_package(current_token.access_token, @application.identifier)

        content_type 'application/zip'
        attachment "documents_package_FT#{@application.identifier}.zip"
        zip_content
      rescue StandardError => e
        halt 500, "Erreur lors du téléchargement: #{e.message}"
      end
    end
  end

  # ==========================================
  # TECHNICAL DASHBOARD
  # ==========================================

  get '/technical' do
    @current_token = Token.current_token
    @markets = Market.order(:created_at).reverse
    @tab = params[:tab] || 'auth'
    erb :'technical/dashboard'
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

    redirect_back = params[:redirect_back] || '/technical'
    redirect redirect_back
  rescue SQLite3::ReadOnlyException => e
    @error = "Database error: #{e.message}. Check file permissions."
    @current_token = Token.current_token rescue nil
    erb :'technical/dashboard'
  rescue StandardError => e
    @error = "Authentication failed: #{e.message}"
    @current_token = Token.current_token rescue nil
    erb :'technical/dashboard'
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

    redirect_back = params[:redirect_back] || '/technical'
    redirect redirect_back
  rescue StandardError => e
    @error = "Token refresh failed: #{e.message}"
    erb :'technical/dashboard'
  end

  get '/clear' do
    Token.clear_tokens
    redirect_back = params[:redirect_back] || '/technical'
    redirect redirect_back
  rescue SQLite3::ReadOnlyException => e
    @error = "Database error: #{e.message}. Check file permissions."
    @current_token = Token.current_token rescue nil
    erb :'technical/dashboard'
  rescue StandardError => e
    @error = "Clear tokens failed: #{e.message}"
    @current_token = Token.current_token rescue nil
    erb :'technical/dashboard'
  end

  # Legacy routes for backward compatibility
  get '/markets/:identifier' do
    redirect "/buyer/markets/#{params[:identifier]}"
  end

  get '/applications/:identifier' do
    redirect "/candidate/applications/#{params[:identifier]}"
  end

  # ==========================================
  # WEBHOOK ENDPOINT
  # ==========================================

  post '/webhooks/voie-rapide' do
    payload = request.body.read
    signature = request.env['HTTP_X_WEBHOOK_SIGNATURE_SHA256']

    # In a real app, you'd verify the signature here
    # For demo purposes, we'll just process the webhook

    webhook_data = JSON.parse(payload)
    event_type = webhook_data['event']

    case event_type
    when 'market.completed'
      handle_market_completion(webhook_data)
    when 'market_application.completed'
      handle_application_completion(webhook_data)
    else
      puts "⚠️ Unknown event type: #{event_type}"
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

  # ==========================================
  # PRIVATE METHODS
  # ==========================================

  private

  def handle_market_completion(webhook_data)
    market_data = webhook_data['market']

    if market_data && market_data['identifier']
      market = Market.find_by_identifier(market_data['identifier'])
      if market
        market.store_webhook_payload!(webhook_data)
        market.mark_completed!(webhook_data)
        puts "✅ Webhook received: Market #{market_data['identifier']} completed"
        puts "🔍 Debug: Webhook payload stored for debugging"
      else
        puts "⚠️  Webhook received for unknown market: #{market_data['identifier']}"
      end
    end
  end

  def handle_application_completion(webhook_data)
    identifier = webhook_data['market_application']['identifier']
    market_identifier = webhook_data['market_identifier']

    application = MarketApplication.find_by_identifier(identifier)

    if application
      application.store_webhook_payload!(webhook_data)
      application.mark_completed!(webhook_data)
      puts "✅ Application #{identifier} completed for market #{market_identifier}"
      puts "🔍 Debug: Webhook payload stored for debugging"
    else
      puts "⚠️ Unknown application: #{identifier}"
    end
  end

  def extract_market_data_from_params
    market_type_codes_array = Array(params[:market_type_codes]).compact

    {
      name: params[:name],
      lot_name: params[:lot_name] && params[:lot_name].empty? ? nil : params[:lot_name],
      deadline: params[:deadline],
      siret: params[:siret],
      market_type_codes: market_type_codes_array
    }
  end

  def validate_market_data(market_data)
    return 'Veuillez remplir le nom du marché.' if market_data[:name].to_s.strip.empty?
    return 'Veuillez remplir la date limite.' if market_data[:deadline].to_s.strip.empty?
    return 'Veuillez remplir le SIRET de l\'organisation.' if market_data[:siret].to_s.strip.empty?
    return 'Le SIRET doit contenir exactement 14 chiffres.' unless market_data[:siret].to_s.match?(/\A\d{14}\z/)
    return 'Veuillez sélectionner une typologie.' if market_data[:market_type_codes].nil? || market_data[:market_type_codes].empty?

    nil
  end
end
