class ClubPushNotificationJob < ApplicationJob
  queue_as :default

  def perform
    current_time = Time.current.in_time_zone("Seoul").strftime("%H:%M")
    Rails.logger.info "[ClubPushNotificationJob] Checking for schedule at #{current_time}"

    # 해당 시간에 예약된 활성 설정 가져오기
    configs = PushNotificationConfig.where(schedule_time: current_time, enabled: true)
    Rails.logger.info "[ClubPushNotificationJob] Found #{configs.count} configs to send"

    configs.each do |config|
      if config.config_type == "night_check"
        send_completion_checks(config)
      elsif [ "morning_affirmation", "evening_reminder" ].include?(config.config_type) || config.config_type.start_with?("test_")
        Rails.logger.info "[ClubPushNotificationJob] Processing general reminder: #{config.config_type}"
        send_general_reminders(config)
      end
    end
  end

  private

  def send_general_reminders(config)
    # For tests, send to ALL users with subscriptions
    if config.config_type.start_with?("test_")
      User.joins(:web_push_subscriptions).distinct.find_each do |user|
        send_to_user(user, config)
      end
      return
    end

    club = RoutineClub.official.first
    unless club
      Rails.logger.error "[ClubPushNotificationJob] Official club not found"
      return
    end

    club.members.confirmed.active.find_each do |membership|
      send_to_user(membership.user, config)
    end
  end

  def send_completion_checks(config)
    club = RoutineClub.official.first
    unless club
      Rails.logger.error "[ClubPushNotificationJob] Official club not found"
      return
    end

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      # 오늘 완료한 루틴이 없는 경우에만 발송
      unless user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: Date.current }).exists?
        send_to_user(user, config)
      end
    end
  end

  def send_to_user(user, config)
    nickname = user.nickname.presence || "멤버"
    title = config.title.gsub("{{nickname}}", nickname)
    content = config.content.gsub("{{nickname}}", nickname)

    Rails.logger.info "[ClubPushNotificationJob] Sending push to User #{user.id} (#{nickname}): #{title}"
    WebPushService.send_notification(user, title, content, "/")
  end
end
