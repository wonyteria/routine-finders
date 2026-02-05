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

  def unsubscribe
    current_user.web_push_subscriptions.where(endpoint: params[:endpoint]).destroy_all
    render json: { status: "ok" }, status: :ok
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
      subscriptions = current_user.web_push_subscriptions

      if subscriptions.empty?
        render plain: "❌ #{nickname}님은 현재 등록된 알림 기기가 없습니다. [앱 푸시 알림 설정] 버튼을 먼저 눌러주세요."
        return
      end

      results = []

      pub = "BOSk9RTXuuwHy1nIfECrhja1c7jy48zRrrTnFczxmPkY7_pfm9uajihHnqvRSObUe7qpoXhNdNxRV62EUvlDBcU="
      priv = "4kb6yCVfIXWwC2tCpFsPXH8sB5uI9cioBwOceY31UkM="

      subscriptions.find_each do |subscription|
        begin
          WebPush.payload_send(
            message: JSON.generate({
              title: "🚀 즉시 테스트 알림",
              body: "#{nickname}님, 이 알림이 보인다면 푸시 서버와 폰이 정상 연결된 것입니다!",
              url: "/"
            }),
            endpoint: subscription.endpoint,
            p256dh: subscription.p256dh_key,
            auth: subscription.auth_key,
            vapid: {
              public_key: pub,
              private_key: priv,
              subject: "mailto:admin@routinefinders.life"
            }
          )
          results << "✅ 기기(#{subscription.endpoint.last(10)}...): 발송 성공"
        rescue => e
          results << "❌ 기기(#{subscription.endpoint.last(10)}...): 발송 실패 (#{e.message})"
        end
      end

      render plain: "발송 결과 (대상: #{nickname}):\n\n" +
                   "Pub Key 상태: #{pub.length}자 (#{pub.first(5)}...)\n" +
                   "Priv Key 상태: #{priv.length}자\n\n" +
                   results.join("\n")
    else
      render plain: "로그인이 필요합니다.", status: :unauthorized
    end
  end
end
