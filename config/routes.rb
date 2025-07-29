# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admins, skip: [:registrations, :passwords, :confirmations, :unlocks]
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  namespace :api do
    namespace :v1 do
      resources :public_markets, only: [:create]
    end
  end

  namespace :buyer do
    resources :public_markets, param: :identifier, only: [] do
      member do
        get ':id', to: 'public_markets#show', as: :step
        put ':id', to: 'public_markets#update'
        patch ':id', to: 'public_markets#update'
      end
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
  
  # Demo functionality (development only)
  post 'demo/create_market', to: 'home#create_demo_market', as: :create_demo_market
  
  root 'home#index'
end
