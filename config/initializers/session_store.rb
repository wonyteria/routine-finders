# Be sure to restart your server when you modify this file.

if Rails.env.production?
  # domain 설정을 제거하여 현재 호스트(www.routinefinders.life)에 세션이 정확히 고착되도록 합니다.
  Rails.application.config.session_store :cookie_store,
    key: "_routine_finders_session",
    secure: true,
    httponly: true,
    same_site: :lax
else
  Rails.application.config.session_store :cookie_store, key: "_routine_finders_session"
end
