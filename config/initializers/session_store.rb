# Be sure to restart your server when you modify this file.

if Rails.env.production?
  # .routinefinders.life 로 설정을 하여 www 여부와 관계없이 세션이 유지되도록 합니다.
  # 이는 소셜 로그인 콜백 시 CSRF 토큰 불일치를 방지하는 데 필수적입니다.
  Rails.application.config.session_store :cookie_store,
    key: "_routine_finders_session",
    domain: ".routinefinders.life",
    secure: true,
    httponly: true,
    same_site: :lax
else
  Rails.application.config.session_store :cookie_store, key: "_routine_finders_session"
end
