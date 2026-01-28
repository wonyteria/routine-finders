# Be sure to restart your server when you modify this file.

if Rails.env.production?
  # domain 설정을 제거하여 Rails가 현재 호스트(www.routinefinders.life)를 자동으로 처리하게 합니다.
  # 이는 최신 브라우저의 쿠키 정책 정책(SameSite: Lax)과 가장 잘 호환됩니다.
  Rails.application.config.session_store :cookie_store,
    key: "_routine_finders_session",
    secure: true,
    httponly: true,
    same_site: :lax
else
  Rails.application.config.session_store :cookie_store, key: "_routine_finders_session"
end
