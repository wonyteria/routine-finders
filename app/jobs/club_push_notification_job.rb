class ClubPushNotificationJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current.in_time_zone("Seoul").strftime("%H:00")

    # 해당 시간에 예약된 활성 설정 가져오기
    configs = PushNotificationConfig.where(schedule_time: current_time, enabled: true)

    configs.each do |config|
      case config.config_type
      when "morning_reminder"
        send_reminders(config)
      when "evening_check"
        send_evening_checks(config)
      end
    end
  end

  private

  def send_reminders(config)
    club = RoutineClub.official.first
    return unless club

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      WebPushService.send_notification(user, config.title, config.content, "/")
    end
  end

  def send_evening_checks(config)
    club = RoutineClub.official.first
    return unless club

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      # 오늘 완료한 루틴이 없는 경우에만 발송
      unless user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: Date.current }).exists?
        WebPushService.send_notification(user, config.title, config.content, "/")
      end
    end
  end
end
