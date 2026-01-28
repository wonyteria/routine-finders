OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# Handle OmniAuth failure
OmniAuth.config.on_failure = Proc.new do |env|
  message_key = env["omniauth.error.type"]
  strategy = env["omniauth.strategy"]&.name

  # 에러 메시지를 안전하게 추출 (nil 방지)
  error_type = message_key.to_s.presence || "unknown_error"
  if error_type.include?("InvalidAuthenticityToken") || error_type.include?("csrf_detected")
    error_type = "session_expired_or_csrf_error"
  end

  # 명시적인 텍스트 응답 바디를 포함하여 'bytesize' 에러를 방지합니다.
  new_path = "/?auth_error=#{error_type}&strategy=#{strategy}"
  [ 302, { "Location" => new_path, "Content-Type" => "text/html" }, [ "Redirecting to #{new_path}" ] ]
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

  provider :kakao, kakao_id, kakao_secret
end
