# frozen_string_literal: true

class RoutineClubNotificationService
  # 입금 확인 알림
  def self.notify_payment_confirmed(membership)
    Notification.create!(
      user: membership.user,
      notification_type: :club_payment_confirmed,
      title: "🎉 입금이 확인되었습니다!",
      content: "#{membership.routine_club.title} 클럽 참여가 승인되었습니다. 이제 클럽 활동을 시작할 수 있습니다."
    )
  end

  # 입금 거부 알림
  def self.notify_payment_rejected(membership, reason = nil)
    content = "#{membership.routine_club.title} 클럽 입금이 거부되었습니다."
    content += " 사유: #{reason}" if reason.present?

    Notification.create!(
      user: membership.user,
      notification_type: :club_payment_rejected,
      title: "❌ 입금이 거부되었습니다",
      content: content
    )
  end

  # 강퇴 알림
  def self.notify_kicked(membership, reason = nil)
    content = "#{membership.routine_club.title} 클럽에서 강퇴되었습니다."
    content += " 사유: #{reason}" if reason.present?

    Notification.create!(
      user: membership.user,
      notification_type: :club_kicked,
      title: "⚠️ 클럽에서 강퇴되었습니다",
      content: content
    )
  end

  # 출석 알림 (매일 아침)
  def self.notify_attendance_reminder(membership)
    Notification.create!(
      user: membership.user,
      notification_type: :club_attendance_reminder,
      title: "📝 오늘의 출석을 체크하세요!",
      content: "#{membership.routine_club.title} 클럽의 오늘 루틴을 완료하고 인증해주세요."
    )
  end

  # 경고 알림
  def self.notify_warning(membership, warning_count, reason = nil)
    content = "#{membership.routine_club.title} 클럽에서 경고를 받았습니다. (총 #{warning_count}회)"
    content += " 사유: #{reason}" if reason.present?

    Notification.create!(
      user: membership.user,
      notification_type: :club_warning,
      title: "⚠️ 경고가 발생했습니다",
      content: content
    )
  end

  # 호스트에게 입금 신청 알림
  def self.notify_host_new_payment(club, membership)
    Notification.create!(
      user: club.host,
      notification_type: :system,
      title: "💰 새로운 입금 신청",
      content: "#{membership.user.nickname}님이 #{club.title} 클럽에 참여 신청했습니다. 입금을 확인해주세요."
    )
  end

  # 일괄 출석 알림 전송 (스케줄러용)
  def self.send_daily_attendance_reminders
    # 활성화된 클럽의 모든 멤버에게 알림
    RoutineClub.active_clubs.find_each do |club|
      club.members.where(payment_status: :confirmed, status: :active).find_each do |membership|
        notify_attendance_reminder(membership)
      end
    end
  end
end
