# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
Rails.application.routes.draw do
  namespace :admin do
    resources :editors do
      resources :webhook_secrets, only: [:create]
    end
    resource :dashboard, only: [:show] do
      get :export, on: :member
    end
    resources :socle_de_base, only: %i[index new create show edit update] do
      collection do
        patch :reorder
        post :import
        post :preview_import
        get :export
      end
      member do
        patch :archive
      end
    end
    resources :categories, only: %i[index new create edit update] do
      collection do
        patch :reorder
      end
    end
    resources :subcategories, only: %i[new create edit update] do
      collection do
        patch :reorder
      end
    end
    resources :audit_logs, only: %i[index show], path: 'historique'
    constraints(->(request) { request.env['warden'].user(:admin_user)&.admin? }) do
      mount MissionControl::Jobs::Engine, at: '/jobs'
    end
    root 'editors#index'
  end
  devise_for :admin_users, skip: %i[registrations passwords confirmations unlocks]
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  namespace :api do
    namespace :v1 do
      resources :public_markets, param: :identifier, only: %i[create update] do
        post :publish, on: :member
        get :configuration_summary, on: :member
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
    patch 'public_markets/:identifier/lots',
      to: 'lots#update_types',
      as: :lot_types

    resources :public_markets, param: :identifier, only: [] do
      member do
        get ':id', to: 'public_markets#show', as: :step
        put ':id', to: 'public_markets#update'
        patch ':id', to: 'public_markets#update'
        post 'retry_sync', to: 'public_markets#retry_sync'
      end
    end

    resources :sync_status, param: :identifier, only: [:show], path: 'public_markets/:identifier/sync_status'
    resources :published, param: :identifier, only: [:show], path: 'public_markets/:identifier/published'
  end

  namespace :candidate do
    get 'dashboard', to: 'dashboards#index', as: :dashboard
    get 'grouping_invitations/:token', to: 'grouping_invitations#show', as: :grouping_invitation

    resource :sessions, only: %i[new create destroy] do
      get :verify
      get :sent
    end

    resources :market_applications, param: :identifier, only: [:destroy] do
      member do
        get 'deadline_passed', to: 'deadline_passed#show', as: :deadline_passed
        get 'grouping_wizard/:id', to: 'grouping_wizard#show', as: :grouping_wizard_step
        patch 'grouping_wizard/:id', to: 'grouping_wizard#update'
        post 'grouping_wizard/members', to: 'grouping_wizard#create_member', as: :grouping_wizard_members
        delete 'grouping_wizard/members/:id', to: 'grouping_wizard#destroy_member', as: :grouping_wizard_member
        get 'company_identification', to: 'company_identifications#show', as: :company_identification
        patch 'company_identification', to: 'company_identifications#update'
        get 'lots', to: 'lot_selections#show', as: :lot_selection
        patch 'lots', to: 'lot_selections#update'
        get 'consultation', to: 'application_consultations#show', as: :consultation
        get 'suivi', to: 'grouping_dashboards#show', as: :grouping_dashboard
        post 'grouping_members/:id/regenerate_invitation_link',
          to: 'grouping_dashboards#regenerate_invitation_link', as: :regenerate_grouping_dashboard_invitation_link
        get ':id', to: 'market_applications#show', as: :step
        put ':id', to: 'market_applications#update'
        patch ':id', to: 'market_applications#update'
        post 'retry_sync', to: 'market_applications#retry_sync'
        delete 'attachments/:signed_id', to: 'attachments#destroy', as: :delete_attachment
      end
    end

    resources :sync_status, param: :identifier, only: [:show],
      path: 'market_application/:identifier/sync_status'
  end

  mount Lookbook::Engine, at: '/lookbook' if Rails.env.development? || Rails.env.sandbox?

  get 'robots.txt', to: 'robots_txt#show', as: :robots_txt
  get 'favicon.ico', to: proc { [204, {}, []] }

  get 'up' => 'rails/health#show', as: :rails_health_check

  get 'candidat', to: 'home#candidate', as: :candidate_home
  get 'acheteur', to: 'home#buyer', as: :buyer_home

  root 'home#index'
end
# rubocop:enable Metrics/BlockLength
