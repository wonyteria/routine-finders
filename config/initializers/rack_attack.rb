# frozen_string_literal: true

# Rack::Attack 설정 - 스팸 및 악의적인 요청 방지
class Rack::Attack
  ### 신뢰할 수 있는 IP (화이트리스트) ###
  # 로컬 개발 환경은 제한하지 않음
  Rack::Attack.safelist("allow-localhost") do |req|
    req.ip == "127.0.0.1" || req.ip == "::1"
  end

  ### 일반 요청 제한 (Throttle) ###

  # 1. 일반 요청: IP당 분당 60회
  throttle("req/ip", limit: 300, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # 2. 로그인 시도: IP당 5분에 20회
  throttle("logins/ip", limit: 20, period: 5.minutes) do |req|
    if req.path == "/auth/kakao" || req.path == "/auth/google_oauth2" || req.path == "/dev_login"
      req.ip
    end
  end

  # 3. 회원가입: IP당 시간당 3회
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/registration" && req.post?
      req.ip
    end
  end

  # 4. API 요청: IP당 분당 30회
  throttle("api/ip", limit: 30, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # 5. 파일 업로드: IP당 분당 10회
  throttle("uploads/ip", limit: 10, period: 1.minute) do |req|
    if req.path.include?("upload") || req.path.include?("attachment")
      req.ip
    end
  end

  # 6. 챌린지/루틴 생성: 사용자당 시간당 10회
  throttle("create_content/user", limit: 10, period: 1.hour) do |req|
    if (req.path.start_with?("/prototype/challenge_builder") ||
        req.path.start_with?("/prototype/routine_builder") ||
        req.path.start_with?("/prototype/gathering_builder")) && req.post?
      req.session[:user_id]
    end
  end

  ### 악의적인 요청 차단 (Blocklist) ###

  # 1. 의심스러운 User-Agent 차단
  blocklist("block-scrapers") do |req|
    # 일반적인 스크래핑 봇 차단
    req.user_agent =~ /curl|wget|python-requests|scrapy/i
  end

  # 2. 특정 경로에 대한 과도한 요청 차단
  blocklist("block-excessive-requests") do |req|
    # 5분 동안 동일 IP에서 300회 이상 요청 시 1시간 차단
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 300, findtime: 5.minutes, bantime: 1.hour) do
      # 요청 카운트
      true
    end
  end

  ### 커스텀 응답 ###

  # Rate limit 초과 시 응답
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "RateLimit-Limit" => match_data[:limit].to_s,
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Content-Type" => "application/json"
    }

    [ 429, headers, [ { error: "요청 횟수 제한을 초과했습니다. 잠시 후 다시 시도해주세요." }.to_json ] ]
  end

  # 차단된 요청에 대한 응답
  self.blocklisted_responder = lambda do |_request|
    [ 403, { "Content-Type" => "application/json" }, [ { error: "접근이 거부되었습니다." }.to_json ] ]
  end

  ### 로깅 ###

  # Rate limit 초과 시 로그 기록
  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Throttled: #{req.ip} - #{req.path}"
  end

  # 차단된 요청 로그 기록
  ActiveSupport::Notifications.subscribe("blocklist.rack_attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] Blocked: #{req.ip} - #{req.path}"
  end
end
