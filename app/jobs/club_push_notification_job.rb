class ClubPushNotificationJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current.in_time_zone("Seoul").strftime("%H:%M")
    Rails.logger.info "[ClubPushNotificationJob] Checking for schedule at #{current_time}"

    # 해당 시간에 예약된 활성 설정 가져오기
    configs = PushNotificationConfig.where(schedule_time: current_time, enabled: true)
    Rails.logger.info "[ClubPushNotificationJob] Found #{configs.count} configs to send"

    configs.each do |config|
      case config.config_type
      when "morning_affirmation", "evening_reminder", "test_1020", "test_1040", "test_1045", "test_1100", "test_1110", "test_1130", "test_1150"
        Rails.logger.info "[ClubPushNotificationJob] Processing general reminder: #{config.config_type}"
        send_general_reminders(config)
      when "night_check"
        send_completion_checks(config)
      end
    end
  end

  private

  def send_general_reminders(config)
    club = RoutineClub.official.first
    return unless club

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      Rails.logger.info "[ClubPushNotificationJob] Sending push to User #{user.id} (#{user.nickname})"
      title = config.title.gsub("{{nickname}}", user.nickname)
      content = config.content.gsub("{{nickname}}", user.nickname)
      WebPushService.send_notification(user, title, content, "/")
    end
  end

  def send_completion_checks(config)
    club = RoutineClub.official.first
    return unless club

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      # 오늘 완료한 루틴이 없는 경우에만 발송
      unless user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: Date.current }).exists?
        title = config.title.gsub("{{nickname}}", user.nickname)
        content = config.content.gsub("{{nickname}}", user.nickname)
        WebPushService.send_notification(user, title, content, "/")
      end
    end
  end
end
