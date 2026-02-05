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

  # Test cases
  PushNotificationConfig.find_or_create_by!(config_type: "test_2220") do |c|
    c.title = "🌙 22시 20분 알림 테스트"
    c.content = "이 알림이 오면 스케줄러가 정상 작동하는 것입니다! 🚀"
    c.schedule_time = "22:20"
    c.enabled = true
  end
end
