Rails.application.routes.draw do
  get "prototype/home"
  get "prototype/login"
  get "prototype/explore"
  get "prototype/synergy"
  get "prototype/my"
  get "prototype/notifications"
  get "prototype/pwa"
  post "prototype/notifications/clear", to: "prototype#clear_notifications"
  post "prototype/record", to: "prototype#record"
  get "prototype/routine_builder", to: "prototype#routine_builder"
  get "prototype/live", to: "prototype#live"
  get "prototype/hub", to: "prototype#hub"
  get "prototype/challenge_builder", to: "prototype#challenge_builder"
  get "prototype/gathering_builder", to: "prototype#gathering_builder"
  get "prototype/club_join", to: "prototype#club_join"
  post "prototype/mark_badges_viewed", to: "prototype#mark_badges_viewed"
  get "prototype/lecture_intro", to: "prototype#lecture_intro"
  # Main Web Application Routes

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  root "prototype#home"
  get "landing", to: "home#landing"
  get "pwa_guide", to: "home#pwa_guide"
  get "achievement_report", to: "home#achievement_report"
  get "badge_roadmap", to: "home#badge_roadmap"
  get "ranking", to: "home#ranking"
  get "host_ranking", to: "home#host_ranking"
  get "users/:id", to: "home#user_profile", as: :user_profile
  post "mark_badges_viewed", to: "home#mark_badges_viewed"
  resources :routine_club_reports, only: [ :index, :show ] do
    collection do
      post :generate_current
    end
  end

  # Authentication routes
  resource :session, only: [ :create, :destroy ]
  resource :registration, only: [ :create ]

  # OmniAuth Callbacks
  match "/auth/:provider/callback", to: "sessions#omniauth", via: [ :get, :post ]
  get "/auth/failure", to: redirect("/")

  # Developer login (development only)
  post "/dev_login", to: "sessions#dev_login" if Rails.env.development?

  # Account restoration
  get "/restore_account", to: "sessions#restore_account"
  post "/restore_account/confirm", to: "sessions#confirm_restore", as: :confirm_restore_account

  # Email verification
  get "verify_email", to: "email_verifications#show"
  post "resend_email_verification", to: "email_verifications#resend"

  # Legacy routes for compatibility
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"

  # Admin routes
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index, :show, :edit, :update, :destroy ]
    resources :challenges, only: [ :index, :show, :edit, :update, :destroy ]
    resources :personal_routines, only: [ :index, :show, :destroy ]
    resources :banners
    resources :routine_clubs
  end

  # Web routes
  resources :challenges do
    member do
      post :join
      delete :leave
      get :clone
      post :apply_refund
    end
    resources :verification_logs, only: [ :new, :create ] do
      member do
        post :approve
        post :reject
      end
    end
    resources :participants, only: [ :index, :update, :destroy ], controller: "challenge_participants"
    resources :applications, only: [ :index, :new, :create ], controller: "challenge_applications" do
      member do
        post :approve
        post :reject
      end
    end
    resources :announcements, only: [ :new, :create, :edit, :update, :destroy ]
    resources :reviews, only: [ :index, :new, :create, :edit, :update, :destroy ]
  end

  # 호스트 전용 챌린지 관리
  resources :hosted_challenges, only: [ :index, :show, :update, :destroy ] do
    member do
      post :complete_refund
      post :batch_approve_verifications
      post :batch_reject_verifications
      post :batch_approve_applications
      post :batch_reject_applications
      post :nudge_participants
    end
  end

  resources :gatherings, only: [ :index, :new, :create ]

  resources :personal_routines, only: [ :index, :create, :edit, :update, :destroy ] do
    member do
      post :toggle
    end
    collection do
      post :update_goals
    end
  end

  # Routine Clubs (유료 루틴 클럽)
  resources :routine_clubs do
    collection do
      get :guide
    end
    member do
      get :manage
      post :join
      post :use_pass
      post :confirm_payment
      post :reject_payment
      post :kick_member
      post :record
      post :cheer
      post :send_message
      post :mark_welcomed
    end
    resources :announcements, only: [ :create, :destroy ]
    resources :gatherings, only: [ :create, :destroy ], controller: "routine_club_gatherings"
  end

  resource :profile, only: [ :show, :edit, :update, :destroy ] do
    collection do
      post :save_account
      get :get_account
    end
  end

  resources :rankings, only: [ :index ]

  resources :rufa_activities, only: [ :index ] do
    resources :claps, controller: "rufa_claps", only: [ :create ]
  end

  resources :routine_templates, only: [] do
    member do
      post :apply
    end
  end

  resources :users, only: [ :show ]

  resources :notifications, only: [ :index ] do
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
        resources :verification_logs, only: [ :index, :create ]
      end

      # Personal Routines
      resources :personal_routines do
        member do
          post :toggle
        end
        collection do
          post :update_goals
        end
      end

      resources :routine_templates, only: [] do
        member do
          post :apply
        end
      end

      resources :rufa_activities do
        resources :claps, controller: "rufa_claps", only: [ :create ]
      end

      resources :routine_club_reports, only: [ :index, :show ] do
        collection do
          post :generate_current
        end
      end

      # Notifications
      resources :notifications, only: [ :index ] do
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
