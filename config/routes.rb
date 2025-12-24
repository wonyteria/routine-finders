Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "home#index"

  # Authentication routes
  resource :session, only: [:create, :destroy]
  resource :registration, only: [:create]
  
  # Email verification
  get "verify_email", to: "email_verifications#show"
  post "resend_email_verification", to: "email_verifications#resend"

  # Legacy routes for compatibility
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Web routes
  resources :challenges do
    member do
      post :join
      delete :leave
    end
  end

  resources :gatherings, only: [:index]

  resources :personal_routines, only: [:create, :destroy] do
    member do
      post :toggle
    end
  end

  resource :profile, only: [:show]

  resources :notifications, only: [:index] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication
      post "login", to: "users#login"
      delete "logout", to: "users#logout"
      get "me", to: "users#me"
      get "participations", to: "users#participations"

      # Challenges
      resources :challenges do
        member do
          post :join
          delete :leave
        end
        resources :verification_logs, only: [:index, :create]
      end

      # Personal Routines
      resources :personal_routines do
        member do
          post :toggle
        end
      end

      # Notifications
      resources :notifications, only: [:index] do
        member do
          post :mark_as_read
        end
        collection do
          post :mark_all_as_read
        end
      end
    end
  end
end
