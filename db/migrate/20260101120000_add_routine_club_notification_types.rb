# frozen_string_literal: true

class AddRoutineClubNotificationTypes < ActiveRecord::Migration[8.1]
  def up
    # notification_type enum에 새로운 값 추가
    # 기존: reminder(0), deadline(1), announcement(2), approval(3), rejection(4),
    #       settlement(5), system(6), application(7), badge_award(8)
    # 추가: club_payment_confirmed(9), club_payment_rejected(10), club_kicked(11),
    #       club_attendance_reminder(12), club_warning(13)
  end

  def down
    # rollback 시 필요한 작업
  end
end
