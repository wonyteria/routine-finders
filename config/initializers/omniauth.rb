OmniAuth.config.allowed_request_methods = [ :post ]
OmniAuth.config.silence_get_warning = true

# Handle OmniAuth failure by redirecting to root with an alert and message for debugging
OmniAuth.config.on_failure = Proc.new do |env|
  message_key = env["omniauth.error.type"]
  [ 302, { "Location" => "/?auth_error=#{message_key}", "Content-Type" => "text/html" }, [] ]
end

# Ensure full_host is set to HTTPS in production
if Rails.env.production?
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
  provider :kakao,
           ENV.fetch("KAKAO_CLIENT_ID", "dummy_kakao_id")
end
