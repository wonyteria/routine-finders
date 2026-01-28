OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# Handle OmniAuth failure by redirecting to root with an alert and message for debugging
OmniAuth.config.on_failure = Proc.new do |env|
  message_key = env["omniauth.error.type"]
  strategy = env["omniauth.strategy"]&.name
  exception = env["omniauth.error"]

  error_details = exception ? "#{exception.class}: #{exception.message}" : "No exception details"
  Rails.logger.error "OmniAuth Failure! strategy=#{strategy}, error_type=#{message_key}, details=#{error_details}"

  # 에러 메시지가 nil이거나 누락된 경우를 대비한 안전 장치
  redirect_msg = message_key.presence || "unknown_error"
  if message_key.to_s.include?("InvalidAuthenticityToken")
    redirect_msg = "session_expired_or_csrf_error"
  end

  new_path = "/?auth_error=#{redirect_msg}&strategy=#{strategy}"

  # Rack 응답 형식을 더 엄격히 준수(body 최소 1개 요소 포함)하여 'bytesize' nil 에러를 방지합니다.
  [ 302, { "Location" => new_path, "Content-Type" => "text/html" }, [ "Redirecting..." ] ]
end

# Ensure full_host is set correctly in production
if Rails.env.production? || ENV["RAILS_ENV"] == "production"
  # SSL 인증서가 www 도메인에만 적용되므로 www를 포함한 절대 경로를 사용합니다.
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
