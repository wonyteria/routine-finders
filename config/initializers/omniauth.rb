Rails.application.config.middleware.use OmniAuth::Builder do
  provider :threads,
           ENV["THREADS_CLIENT_ID"],
           ENV["THREADS_CLIENT_SECRET"],
           scope: "threads_basic,threads_content_publish"
end
