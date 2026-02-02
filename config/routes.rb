Rails.application.routes.draw do
  # Authentication
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout
  patch "toggle_admin_tools", to: "sessions#toggle_admin_tools", as: :toggle_admin_tools

  # Users (admin management)
  resources :users, except: [:show]

  # Events
  resources :events do
    resources :posts, only: [:new, :create]
    member do
      get :display
      get :winners
      get :winners_worksheet
      get :pdf
      post :generate_pdf
      patch :end_event
    end
  end
  root "events#home"

  # Leagues
  resources :leagues do
    member do
      get :teams
    end
  end

  # Conferences
  resources :conferences, except: [ :index ]

  # Teams
  resources :teams do
    member do
      get :styles
    end
  end

  # Affiliations
  resources :affiliations

  # Colors
  resources :colors, except: [ :index, :show ]

  # Styles
  resources :styles, except: [ :index, :show ]

  # Players
  resources :players do
    collection do
      patch :bulk_update_chances
    end
    member do
      patch :deactivate
      patch :activate
      get :winners
    end
  end

  # Games
  resources :games, except: [ :index ] do
    collection do
      get :fetch_espn_data
    end
    member do
      patch :swap_teams
      patch :refresh_scores
      patch :manual_scores
    end
  end

  # Posts (nested new/create under events, standalone show/edit/update/destroy)
  resources :posts, only: [:show, :edit, :update, :destroy] do
    member do
      get :content
      post :send_email
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Timezone preference (cookie-based)
  patch "timezone" => "timezone#update", as: :timezone

  # Status endpoint for deployment smoke testing
  get "status" => "status#show", as: :status, defaults: { format: :json }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
