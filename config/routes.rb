# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :editors do
      resources :webhook_secrets, only: [:create]
    end
    mount MissionControl::Jobs::Engine, at: '/jobs'
    root 'editors#index'
  end
  devise_for :admin_users, skip: %i[registrations passwords confirmations unlocks]
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  namespace :api do
    namespace :v1 do
      resources :public_markets, only: [:create] do
        resources :market_applications, only: [:create]
      end
      resources :market_applications, only: [] do
        member do
          get :attestation
          get :documents_package
        end
      end
    end
  end

  namespace :buyer do
    resources :public_markets, param: :identifier, only: [] do
      member do
        get ':id', to: 'public_markets#show', as: :step
        put ':id', to: 'public_markets#update'
        patch ':id', to: 'public_markets#update'
        post 'retry_sync', to: 'public_markets#retry_sync'
      end
    end

    resources :sync_status, param: :identifier, only: [:show], path: 'public_markets/:identifier/sync_status'
  end

  namespace :candidate do
    resources :market_applications, param: :identifier, only: [] do
      member do
        get ':id', to: 'market_applications#show', as: :step
        put ':id', to: 'market_applications#update'
        patch ':id', to: 'market_applications#update'
        post 'retry_sync', to: 'market_applications#retry_sync'
      end
    end

    resources :sync_status, param: :identifier, only: [:show],
      path: 'market_application/:identifier/sync_status'
  end

  get 'up' => 'rails/health#show', as: :rails_health_check

  root 'home#index'
end
