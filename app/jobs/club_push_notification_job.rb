class ClubPushNotificationJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "[ClubPushNotificationJob] Starting global push check"

    # 모든 활성 설정에 대해 각각 해당 시간대인 유저를 찾음
    PushNotificationConfig.where(enabled: true).find_each do |config|
      # 현재 시각이 schedule_time과 일치하는 타임존 목록 계산
      matching_tzs = ActiveSupport::TimeZone.all.select do |tz|
        Time.current.in_time_zone(tz.name).strftime("%H:%M") == config.schedule_time
      end.flat_map { |tz| [ tz.name, tz.tzinfo.name ] }.uniq

      next if matching_tzs.empty?

      Rails.logger.info "[ClubPushNotificationJob] Found config #{config.config_type} matching TZs: #{matching_tzs.join(', ')}"

      if config.config_type == "night_check"
        send_completion_checks(config, matching_tzs)
      elsif [ "morning_affirmation", "evening_reminder" ].include?(config.config_type)
        send_general_reminders(config, matching_tzs)
      end
    end
  end

  private

  def send_general_reminders(config, matching_tzs)
    # 해당 타임존을 가진 활성 유저에게 발송
    User.where(deleted_at: nil, time_zone: matching_tzs).find_each do |user|
      send_to_user(user, config)
    end
  end

  def send_completion_checks(config, matching_tzs)
    # 해당 타임존을 가진 활성 유저 중 오늘 루틴 인증이 없는 유저에게 발송
    User.where(deleted_at: nil, time_zone: matching_tzs).find_each do |user|
      # 유저의 로컬 시간 기준으로 '오늘' 완료한 루틴이 없는지 체크
      Time.use_zone(user.time_zone) do
        unless user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: Date.current }).exists?
          send_to_user(user, config)
        end
      end
    end
  end

  def send_to_user(user, config)
    # 알림 설정 확인
    unless user.notification_enabled?(config.config_type)
      Rails.logger.info "[ClubPushNotificationJob] Skipping push for User #{user.id} due to preferences (#{config.config_type})"
      return
    end

    nickname = user.nickname.presence || "멤버"
    title = config.title.gsub("{{nickname}}", nickname)
    content = config.random_content(nickname)

    Rails.logger.info "[ClubPushNotificationJob] Sending push to User #{user.id} (#{nickname}): #{title}"
    WebPushService.send_notification(user, title, content, config.link_url || "/")
  end
end
