OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# Handle OmniAuth failure by redirecting to root with an alert and message for debugging
OmniAuth.config.on_failure = Proc.new do |env|
  message_key = env["omniauth.error.type"]
  strategy = env["omniauth.strategy"]&.name
  Rails.logger.error "OmniAuth Failure: strategy=#{strategy}, error_type=#{message_key}"

  [ 302, { "Location" => "/?auth_error=#{message_key}&strategy=#{strategy}", "Content-Type" => "text/html" }, [] ]
end

# Ensure full_host is set to HTTPS in production
if Rails.env.production? || ENV['RAILS_ENV'] == 'production'
  OmniAuth.config.full_host = "https://www.routinefinders.life"
end

Rails.logger.info "OmniAuth full_host configured as: #{OmniAuth.config.full_host || 'Automatic'}"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.development?
  provider :threads,
           ENV.fetch("THREADS_CLIENT_ID", "dummy_client_id"),
           ENV.fetch("THREADS_CLIENT_SECRET", "dummy_client_secret"),
           scope: "threads_basic"
  provider :google_oauth2,
           ENV.fetch("GOOGLE_CLIENT_ID", "dummy_google_id"),
           ENV.fetch("GOOGLE_CLIENT_SECRET", "dummy_google_secret"),
           scope: "email, profile"
  # 카카오 로그인 설정 (환경 변수가 우선하며, 없을 경우 제공된 기본값을 사용합니다)
  kakao_id = ENV.fetch("KAKAO_CLIENT_ID", "f959f8ada6c21d791ef5be7f4257e19e")
  kakao_secret = ENV.fetch("KAKAO_CLIENT_SECRET", "W9EtJ9jd2zFJU0PKCJhnbUhRUDNHTq5s")

  provider :kakao, kakao_id, kakao_secret, callback_path: "/auth/kakao/callback"
end
