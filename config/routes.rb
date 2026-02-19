# Deployment Trigger: Retry Push 2026-02-04 01:27
Rails.application.routes.draw do
  # Main Service Routes (Formerly Prototype)
  root "prototype#home"
  get "home", to: "prototype#home", as: :prototype_home
  get "login", to: "prototype#login", as: :prototype_login
  get "explore", to: "prototype#explore", as: :prototype_explore
  get "synergy", to: "prototype#synergy", as: :prototype_synergy
  get "my", to: "prototype#my", as: :prototype_my
  get "notifications_center", to: "prototype#notifications", as: :prototype_notifications

  # PWA routes
  get "/service-worker.js" => "pwa#service_worker", as: :pwa_service_worker
  get "/manifest.json" => "pwa#manifest", as: :pwa_manifest
  get "/offline" => "pwa#offline", as: :pwa_offline
  post "/pwa/subscribe" => "pwa#subscribe", as: :pwa_subscribe
  delete "/pwa/subscribe" => "pwa#unsubscribe", as: :pwa_unsubscribe
  post "/pwa/dismiss_notice" => "pwa#dismiss_notice", as: :pwa_dismiss_push_notice


  get "pwa", to: "prototype#pwa", as: :prototype_pwa
  post "notifications/clear", to: "prototype#clear_notifications", as: :prototype_clear_notifications
  post "record", to: "prototype#record", as: :prototype_record
  get "routine_builder", to: "prototype#routine_builder", as: :prototype_routine_builder
  get "routine_editor/:id", to: "prototype#routine_editor", as: :prototype_routine_editor
  get "routines", to: "prototype#routines", as: :prototype_routines
  get "live", to: "prototype#live", as: :prototype_live
  get "hub", to: "prototype#hub", as: :prototype_hub
  get "challenge_builder", to: "prototype#challenge_builder", as: :prototype_challenge_builder
  get "gathering_builder", to: "prototype#gathering_builder", as: :prototype_gathering_builder
  get "club_join", to: "prototype#club_join", as: :prototype_club_join
  post "mark_badges_viewed_legacy", to: "prototype#mark_badges_viewed", as: :mark_badges_viewed_prototype
  patch "update_goals_main", to: "prototype#update_goals", as: :prototype_update_goals
  patch "update_profile_main", to: "prototype#update_profile", as: :prototype_update_profile
  patch "update_notification_preferences", to: "prototype#update_notification_preferences", as: :prototype_update_notification_preferences
  get "lecture_intro", to: "prototype#lecture_intro", as: :prototype_lecture_intro
  get "user_card/:id", to: "prototype#user_profile", as: :prototype_user_card

  # Admin & Management (Formerly Prototype Admin)
  get "admin_center", to: "prototype#admin_dashboard", as: :prototype_admin_dashboard
  get "admin_center/clubs", to: "prototype#club_management", as: :prototype_admin_clubs
  get "admin_center/clubs/batch_reports", to: "prototype#batch_reports", as: :prototype_batch_reports
  get "admin_center/member_reports/:user_id", to: "prototype#member_reports", as: :prototype_member_reports
  post "admin_center/broadcast", to: "prototype#broadcast"
  post "admin_center/update_user_role", to: "prototype#update_user_role"
  post "admin_center/update_user_status", to: "prototype#update_user_status"
  post "admin_center/update_content_basic", to: "prototype#update_content_basic"
  post "admin_center/approve_challenge", to: "prototype#approve_challenge"
  delete "admin_center/delete_content/:id", to: "prototype#delete_content", as: :prototype_delete_content
  post "admin_center/notify_host/:id", to: "prototype#notify_host", as: :prototype_notify_host
  post "admin_center/purge_cache", to: "prototype#purge_cache"
  post "admin_center/reset_users", to: "prototype#reset_users", as: :prototype_reset_users
  patch "admin_center/update_club_lounge", to: "prototype#update_club_lounge", as: :prototype_update_club_lounge
  post "admin_center/create_club_announcement", to: "prototype#create_club_announcement", as: :prototype_create_club_announcement
  patch "admin_center/update_club_announcement/:id", to: "prototype#update_club_announcement", as: :prototype_update_club_announcement
  post "admin_center/confirm_club_payment", to: "prototype#confirm_club_payment", as: :prototype_confirm_club_payment
  post "admin_center/reject_club_payment", to: "prototype#reject_club_payment", as: :prototype_reject_club_payment
  get "admin_center/clubs/weekly_report", to: "prototype#admin_weekly_check", as: :prototype_admin_weekly_check
  get "admin_center/analyze_member_performance", to: "prototype#analyze_member_performance", as: :prototype_analyze_member_performance
  get "admin_center/users/:id", to: "prototype#admin_user_show", as: :prototype_admin_user_show
  patch "admin_center/update_push_config", to: "prototype#update_push_config", as: :prototype_update_push_config



  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path
  get "landing", to: "home#landing"
  get "pwa_guide", to: "home#pwa_guide"
  get "achievement_report", to: "home#achievement_report"
  get "badge_roadmap", to: "home#badge_roadmap"
  get "ranking", to: "home#ranking"
  get "host_ranking", to: "home#host_ranking"
  get "users/:id", to: "home#user_profile", as: :user_profile
  post "mark_badges_viewed", to: "home#mark_badges_viewed"
  post "track_share", to: "home#track_share"
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
  get "/auth/failure", to: "sessions#omniauth_failure"

  # Developer login (development only)
  post "/dev_login", to: "sessions#dev_login" if Rails.env.development?

  # Account restoration
  get "/restore_account", to: "sessions#restore_account"
  post "/restore_account/confirm", to: "sessions#confirm_restore", as: :confirm_restore_account

  # Onboarding
  post "/complete_onboarding", to: "sessions#complete_onboarding"

  # Legacy routes for compatibility
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "logout", to: "sessions#destroy"

  # Admin routes
  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: [ :index, :show, :edit, :update, :destroy ] do
      member do
        patch :toggle_status
      end
    end
    resources :challenges, only: [ :index, :show, :edit, :update, :destroy ]
    resources :personal_routines, only: [ :index, :show, :destroy ]
    resources :banners
    resources :routine_clubs
  end

  # Web routes
  resources :challenges, except: [ :index ] do
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

  resources :gatherings, only: [ :new, :create ]

  resources :personal_routines, only: [ :create, :edit, :update, :destroy ] do
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
      post :warn_member
      post :record
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

  resources :rufa_activities, only: [ :index ]

  resources :routine_templates, only: [] do
    member do
      post :apply
    end
  end

  resources :users, only: [ :show ]

  resources :notifications, only: [] do
    member do
      post :mark_as_read
    end
    collection do
      post :mark_all_as_read
    end
  end

  # Redirect old index paths to new experience
  get "challenges", to: "prototype#explore"
  get "gatherings", to: "prototype#explore", type: "gathering"
  get "personal_routines", to: "prototype#my"
  get "notifications", to: "prototype#notifications"
  get "profile", to: "prototype#my"
  get "rankings", to: "prototype#synergy", tab: "ranking"

  # Redirect old prototype paths to new main paths for SEO and bookmark stability
  get "prototype/home", to: redirect("/")
  get "prototype/login", to: redirect("/login")
  get "prototype/explore", to: redirect("/explore")
  get "prototype/synergy", to: redirect("/synergy")
  get "prototype/my", to: redirect("/my")
  get "prototype/notifications", to: redirect("/notifications_center")
  get "prototype/routines", to: redirect("/routines")
  get "prototype/live", to: redirect("/live")
  get "prototype/hub", to: redirect("/hub")
  get "prototype/club_join", to: redirect("/club_join")
  get "prototype/admin", to: redirect("/admin_center")
  get "prototype/admin/clubs", to: redirect("/admin_center/clubs")

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

      resources :rufa_activities

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
