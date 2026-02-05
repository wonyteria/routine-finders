# frozen_string_literal: true

Rails.application.config.after_initialize do
  # Skip during asset precompilation where DB might not be available
  next if ENV["SECRET_KEY_BASE_DUMMY"] || !ActiveRecord::Base.connection.data_source_exists?("routine_clubs")

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

  PushNotificationConfig.find_or_create_by!(config_type: "test_1245") do |c|
    c.title = "🚀 오후 12시 45분 테스트"
    c.content = "배포 성공 후 첫 알림 테스트입니다!"
    c.schedule_time = "12:45"
    c.enabled = true
  end

  PushNotificationConfig.find_or_create_by!(config_type: "test_1300") do |c|
    c.title = "🚀 오후 1시 정각 테스트"
    c.content = "안정성 확인을 위한 추가 테스트입니다."
    c.schedule_time = "13:00"
    c.enabled = true
  end

  PushNotificationConfig.find_or_create_by!(config_type: "test_1340") do |c|
    c.title = "🚀 오후 1시 40분 최종 테스트"
    c.content = "이 알림이 오면 모든 멤버에게 발송되는 로직이 검증된 것입니다!"
    c.schedule_time = "13:40"
    c.enabled = true
  end

  PushNotificationConfig.find_or_create_by!(config_type: "test_1555") do |c|
    c.title = "🚀 오후 3시 55분 스케줄 테스트"
    c.content = "이 알림은 서버가 스스로 스케줄에 맞춰 보낸 것입니다! 완벽합니다!"
    c.schedule_time = "15:55"
    c.schedule_time = "15:55"
    c.enabled = true
  end

  PushNotificationConfig.find_or_create_by!(config_type: "test_1610") do |c|
    c.title = "🚀 오후 4시 10분 스케줄 테스트"
    c.content = "이 알림은 4시 10분에 정확히 도착해야 합니다!"
    c.schedule_time = "16:10"
    c.enabled = true
  end
end
