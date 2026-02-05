class PwaController < ApplicationController
  # Skip CSRF protection for service worker, manifest and subscription
  skip_before_action :verify_authenticity_token, only: [ :service_worker, :manifest, :subscribe, :dismiss_notice ]
  before_action :require_login, only: [ :subscribe, :dismiss_notice ]

  def manifest
    render file: "app/views/pwa/manifest.json.erb", content_type: "application/manifest+json"
  end

  def service_worker
    render file: "app/views/pwa/service-worker.js", content_type: "application/javascript"
  end

  def offline
    render file: "app/views/pwa/offline.html", layout: false
  end

  def subscribe
    subscription = current_user.web_push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    subscription.p256dh_key = params[:p256dh]
    subscription.auth_key = params[:auth]

    if subscription.save
      render json: { status: "ok" }, status: :ok
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def dismiss_notice
    # JSON column handles string keys
    current_user.notification_preferences ||= {}
    current_user.notification_preferences["push_onboarding_dismissed"] = true

    if current_user.save
      render json: { status: "ok" }, status: :ok
    else
      render json: { error: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def push_test
    if current_user
      nickname = current_user.nickname.presence || "멤버"
      WebPushService.send_notification(
        current_user,
        "🚀 즉시 테스트 알림",
        "#{nickname}님, 이 알림이 보인다면 푸시 서버 통로가 정상적으로 연결된 것입니다!",
        "/"
      )
      render plain: "Push sent to #{nickname}! Please check your phone."
    else
      render plain: "Please login first.", status: :unauthorized
    end
  end
end
