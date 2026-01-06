OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true

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
           ENV.fetch("KAKAO_CLIENT_ID", "dummy_kakao_id"),
           ENV.fetch("KAKAO_CLIENT_SECRET", "dummy_kakao_secret")
end
