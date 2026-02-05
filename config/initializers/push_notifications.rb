# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Ensure official club exists
  RoutineClub.ensure_official_club

  # Ensure default push notification configurations exist
  PushNotificationConfig.morning_affirmation
  PushNotificationConfig.evening_reminder
  PushNotificationConfig.night_check

  # Add test cases for verification if needed
  PushNotificationConfig.find_or_create_by!(config_type: "test_1130") do |c|
    c.title = "🚀 11시 30분 테스트"
    c.content = "서버 배포 후 첫 테스트입니다! 알림이 잘 오나요?"
    c.schedule_time = "11:30"
    c.enabled = true
  end

  PushNotificationConfig.find_or_create_by!(config_type: "test_1150") do |c|
    c.title = "🚀 11시 50분 테스트"
    c.content = "이 알림이 오면 모든 설정이 완벽합니다!"
    c.schedule_time = "11:50"
    c.enabled = true
  end

  PushNotificationConfig.find_or_create_by!(config_type: "test_1230") do |c|
    c.title = "🚀 12시 30분 테스트"
    c.content = "스케줄러 활성화 후 최종 테스트입니다! 이번에는 꼭 와야 해요."
    c.schedule_time = "12:30"
    c.enabled = true
  end
end
