OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# Handle OmniAuth failure
# Rails 표준 에러 처리에 맡겨 bytesize nil 에러를 원천 차단합니다.
OmniAuth.config.on_failure = Proc.new do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end

# Ensure full_host is set correctly in production
if Rails.env.production? || ENV["RAILS_ENV"] == "production"
  OmniAuth.config.full_host = "https://www.routinefinders.life"
end

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

  kakao_id = ENV.fetch("KAKAO_CLIENT_ID", "f959f8ada6c21d791ef5be7f4257e19e")
  kakao_secret = ENV.fetch("KAKAO_CLIENT_SECRET", "W9EtJ9jd2zFJU0PKCJhnbUhRUDNHTq5s")
  provider :kakao, kakao_id, kakao_secret
end
