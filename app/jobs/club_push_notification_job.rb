class ClubPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(type)
    case type
    when "morning_reminder"
      send_morning_reminders
    when "evening_check"
      send_evening_checks
    end
  end

  private

  def send_morning_reminders
    # 활성화된 공식 클럽 멤버들에게 아침 알림 발송
    club = RoutineClub.official.first
    return unless club

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      WebPushService.send_notification(
        user,
        "☀️ 루파 클럽 아침 리마인더",
        "#{user.nickname}님, 오늘도 나를 위한 루틴으로 활기찬 하루를 시작해볼까요?",
        "/"
      )
    end
  end

  def send_evening_checks
    # 저녁에 루틴 체크 안 한 멤버들에게 알림 발송
    club = RoutineClub.official.first
    return unless club

    club.members.confirmed.active.find_each do |membership|
      user = membership.user
      # 오늘 완료한 루틴이 없는 경우
      unless user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: Date.current }).exists?
        WebPushService.send_notification(
          user,
          "🌙 루파 클럽 저녁 체크",
          "오늘의 성장을 기록하셨나요? 잊기 전에 루틴을 체크해 보세요!",
          "/"
        )
      end
    end
  end
end
