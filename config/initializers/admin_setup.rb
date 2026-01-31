# frozen_string_literal: true

# 서버 시작 시 특정 사용자(특히 카카오 유일 사용자)를 슈퍼 관리자로 자동 설정하는 스크립트
Rails.application.config.after_initialize do
  # 프로덕션 서버에서 DB 초기화 등으로 권한이 풀리는 것을 방지하기 위해 상시 체크합니다.

  begin
    # 1. 카카오 제공자로 가입한 사용자 체크 (사용자님이 말씀하신 유일한 카카오 계정 우선순위)
    kakao_user = User.where(provider: "kakao").first
    if kakao_user && !kakao_user.super_admin?
      kakao_user.super_admin!
      Rails.logger.info "[AdminSetup] ✓ 유일한 카카오 사용자(#{kakao_user.nickname})를 슈퍼 관리자로 자동 설정했습니다."
    end

    # 2. 이메일로 추가 체크 (jorden00@naver.com)
    target_emails = [ "jorden00@naver.com" ]
    target_emails.each do |email|
      user = User.find_by(email: email)
      if user && !user.super_admin?
        user.super_admin!
        Rails.logger.info "[AdminSetup] ✓ 이메일(#{email}) 사용자를 슈퍼 관리자로 설정했습니다."
      end
    end

    # 3. 닉네임으로 추가 체크 (율파진빠)
    if (user = User.find_by(nickname: "율파진빠")) && !user.super_admin?
      user.super_admin!
      Rails.logger.info "[AdminSetup] ✓ 닉네임(율파진빠) 사용자를 슈퍼 관리자로 설정했습니다."
    end

  rescue => e
    # 초기 로딩 시 테이블이 없거나 하는 장애 상황 방지
    Rails.logger.error "[AdminSetup] 관리자 권한 자동 설정 중 오류 발생: #{e.message}"
  end
end
