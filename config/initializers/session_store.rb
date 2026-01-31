# Be sure to restart your server when you modify this file.

if Rails.env.production?
  # .routinefinders.life는 서브도메인(www) 간 세션 공유를 위해 사용되지만,
  # 현재 www로만 강제 접속하고 있으므로 도메인 설정을 제거하여 쿠키 충돌을 방지합니다.
  Rails.application.config.session_store :cookie_store,
    key: "_routine_finders_session",
    expire_after: 1.year,
    secure: true,
    httponly: true,
    same_site: :lax
else
  Rails.application.config.session_store :cookie_store,
    key: "_routine_finders_session",
    expire_after: 1.year
end
