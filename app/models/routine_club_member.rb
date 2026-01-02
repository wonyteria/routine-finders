# frozen_string_literal: true

class RoutineClubMember < ApplicationRecord
  # Enums
  enum :payment_status, { pending: 0, confirmed: 1, rejected: 2 }, prefix: true
  enum :status, { active: 0, warned: 1, kicked: 2, left: 3 }, prefix: true

  # Scopes
  scope :confirmed, -> { where(payment_status: :confirmed) }
  scope :active, -> { where(status: :active) }

  # Associations
  belongs_to :routine_club
  belongs_to :user
  has_many :attendances, class_name: "RoutineClubAttendance", dependent: :destroy
  has_many :penalties, class_name: "RoutineClubPenalty", dependent: :destroy

  # Validations
  validates :user_id, uniqueness: { scope: :routine_club_id }
  validates :depositor_name, presence: true, if: -> { payment_status_pending? }
  validates :contact_info, presence: true, if: -> { payment_status_pending? }
  validates :paid_amount, presence: true, numericality: { greater_than: 0 }

  # Callbacks
  before_create :set_membership_dates
  after_update :update_club_member_count, if: :saved_change_to_payment_status?

  # Methods
  def confirm_payment!
    update!(
      payment_status: :confirmed,
      deposit_confirmed_at: Time.current
    )

    # 알림 전송
    RoutineClubNotificationService.notify_payment_confirmed(self)
  end

  def reject_payment!(reason = nil)
    update!(
      payment_status: :rejected,
      kick_reason: reason
    )

    # 알림 전송
    RoutineClubNotificationService.notify_payment_rejected(self, reason)
  end

  def kick!(reason)
    update!(
      status: :kicked,
      kick_reason: reason
    )

    # 알림 전송
    RoutineClubNotificationService.notify_kicked(self, reason)
  end

  def update_attendance_stats!
    total_days = attendances.count
    present_days = attendances.where(status: :present).count
    excused_days = attendances.where(status: :excused).count

    update!(
      attendance_count: present_days,
      absence_count: total_days - (present_days + excused_days),
      attendance_rate: total_days > 0 ? ((present_days + excused_days).to_f / total_days * 100).round(2) : 0.0
    )

    recalculate_growth_points!
  end

  def use_relaxation_pass!(date = Date.current)
    return false if used_passes_count >= 3

    attendance = attendances.find_or_initialize_by(attendance_date: date, routine_club: routine_club)
    return false unless attendance.status_absent? || attendance.new_record?

    transaction do
      attendance.update!(status: :excused)
      increment!(:used_passes_count)
      update_attendance_stats!
    end
    true
  end

  def recalculate_growth_points!
    # Points logic:
    # 1. 10 pts per present day
    # 2. 5 pts per clap received
    # 3. 50 pts Golden Fire bonus (per 7-day perfect streak)

    points = 0
    points += attendances.where(status: :present).count * 10
    points += attendances.sum(:cheers_count) * 5

    # Golden Fire (7-day streaks)
    # Simple check: how many perfect weeks (7 attendances with status present/excused)
    # For now, let's just count total present/7
    points += (attendances.where(status: :present).count / 7) * 50

    update!(growth_points: points)
  end

  def remaining_passes
    3 - (used_passes_count || 0)
  end

  def can_participate?
    payment_status_confirmed? && status_active?
  end

  private

  def set_membership_dates
    self.joined_at ||= Time.current
    self.membership_start_date ||= routine_club.start_date
    self.membership_end_date ||= routine_club.end_date
  end

  def update_club_member_count
    if payment_status_confirmed? && saved_change_to_payment_status?[1] == "confirmed"
      routine_club.increment!(:current_members)
    elsif payment_status_rejected? && saved_change_to_payment_status?[0] == "confirmed"
      routine_club.decrement!(:current_members)
    end
  end
end
