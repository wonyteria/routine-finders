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
    # "징검다리 로직": 루틴이 설정된 요일(약속한 날)들만 분모로 계산
    # user의 personal_routines 중 루틴이 설정된 요일들을 가져옴
    scheduled_wdays = user.personal_routines.pluck(:days).flatten.uniq.map(&:to_i)

    # 해당 멤버의 전체 출석 기록 중, 루틴이 설정된 요일에 해당하는 기록만 필터링
    relevant_attendances = attendances.select { |a| scheduled_wdays.include?(a.attendance_date.wday) }

    total_days = relevant_attendances.size
    present_days = relevant_attendances.select { |a| a.status == "present" }.size
    excused_days = relevant_attendances.select { |a| a.status == "excused" }.size

    update!(
      attendance_count: present_days,
      absence_count: total_days - (present_days + excused_days),
      attendance_rate: total_days > 0 ? ((present_days + excused_days).to_f / total_days * 100).round(2) : 0.0
    )

    recalculate_growth_points!
  end

  # 기수 완주 조건 확인 (출석률 70% 이상 + 제명되지 않음)
  def met_completion_criteria?
    status_active? && attendance_rate >= (routine_club.completion_attendance_rate || 70.0)
  end

  def use_relax_pass!(date = Date.current)
    return false if remaining_relax_passes <= 0

    attendance = attendances.find_or_initialize_by(attendance_date: date, routine_club: routine_club)
    return false if attendance.persisted? && (attendance.status_present? || attendance.status_excused?)

    transaction do
      attendance.update!(status: :excused)
      increment!(:used_relax_passes_count)
      update_attendance_stats!
    end
    true
  end

  def use_save_pass!(date = Date.current)
    return false if remaining_save_passes <= 0

    attendance = attendances.find_or_initialize_by(attendance_date: date, routine_club: routine_club)
    # Save pass can be used on missed days (absent or not present)
    return false if attendance.persisted? && (attendance.status_present? || attendance.status_excused?)

    transaction do
      attendance.update!(status: :excused)
      increment!(:used_save_passes_count)
      update_attendance_stats!
    end
    true
  end

  def recalculate_growth_points!
    # Points logic:
    # 1. 10 pts per present day (기본 출석)
    # 2. 5 pts per clap received (동료 응원)
    # 3. Bonus for routine achievement:
    #    - 100% achievement: +20 pts bonus
    #    - 50-99% achievement: +5 pts bonus
    # 4. 20 pts Golden Fire bonus (per 7-day perfect streak)

    points = 0
    attendances_data = attendances.where(status: :present)

    # 1. Base Attendance
    points += attendances_data.count * 10

    # 2. Cheers
    points += attendances_data.sum(:cheers_count) * 5

    # 3. Achievement Bonuses
    attendances_data.each do |a|
      if a.achievement_rate.to_f >= 100.0
        points += 20
      elsif a.achievement_rate.to_f >= 50.0
        points += 5
      end
    end

    # 4. Golden Fire (7-day streaks)
    points += (attendances_data.count / 7) * (routine_club.golden_fire_bonus || 20)

    update!(growth_points: points)
  end

  def update_achievement_stats!
    # 멤버십 참여 기간 내의 모든 활성화된 루틴 달성률의 평균을 구함
    start_date = membership_start_date
    end_date = [ Date.current, membership_end_date ].min
    days = (end_date - start_date).to_i + 1
    return if days <= 0

    # 이 클럽의 membership 기간 동안의 유저 달성률 평균
    # 여기서는 간단히 지금까지의 출석 기록에 저장된 achievement_rate 평균으로 계산
    avg_rate = attendances.where(status: :present).average(:achievement_rate) || 0
    update!(achievement_rate: avg_rate.to_f.round(1))
  end

  def remaining_relax_passes
    return 0 unless payment_status_confirmed?
    ensure_monthly_refill!
    (routine_club.relax_pass_limit || 3) - (used_relax_passes_count || 0)
  end

  def remaining_save_passes
    return 0 unless payment_status_confirmed?
    ensure_monthly_refill!
    (routine_club.save_pass_limit || 3) - (used_save_passes_count || 0)
  end

  def remaining_passes
    remaining_relax_passes + remaining_save_passes
  end

  def ensure_monthly_refill!
    return unless payment_status_confirmed? && status_active?

    # If never refilled or last refill was in a previous month
    if last_pass_refill_at.nil? || last_pass_refill_at.beginning_of_month < Time.current.beginning_of_month
      update!(
        used_relax_passes_count: 0,
        used_save_passes_count: 0,
        used_passes_count: 0, # Keep for legacy
        last_pass_refill_at: Time.current
      )
    end
  end

  def can_participate?
    payment_status_confirmed? && (status_active? || status_warned?) && Date.current >= membership_start_date
  end

  private

  def set_membership_dates
    self.joined_at ||= Time.current
    self.membership_start_date ||= routine_club.start_date
    self.membership_end_date ||= routine_club.end_date
  end

  def update_club_member_count
    # saved_change_to_payment_status returns [old_value, new_value]
    if payment_status_confirmed? && saved_change_to_payment_status&.last == "confirmed"
      routine_club.increment!(:current_members)
    elsif payment_status_rejected? && saved_change_to_payment_status&.first == "confirmed"
      routine_club.decrement!(:current_members)
    end
  end
end
