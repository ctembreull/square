Rails.application.routes.draw do
  # Events
  resources :events do
    member do
      patch :activate
      patch :deactivate
      patch :end_event
    end
  end
  root "events#home"

  # Leagues
  resources :leagues

  # Conferences
  resources :conferences, except: [ :index ]

  # Teams
  resources :teams

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
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
