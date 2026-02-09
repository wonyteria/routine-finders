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
  validates :paid_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_create :set_membership_dates
  after_update :update_club_member_count, if: :saved_change_to_payment_status?

  # Methods
  def confirm_payment!
    update!(
      payment_status: :confirmed,
      status: :active,
      deposit_confirmed_at: Time.current
    )

    # 알림 전송
    RoutineClubNotificationService.notify_payment_confirmed(self)

    # 뱃지 지급
    award_season_badge
  end

  def reject_payment!(reason = nil)
    update!(
      payment_status: :rejected,
      kick_reason: reason
    )

    # 알림 전송
    RoutineClubNotificationService.notify_payment_rejected(self, reason)
  end

  # 경고 부여 (날짜 지정 가능)
  def warn!(reason, date = Time.current)
    transaction do
      penalties.create!(
        routine_club: routine_club,
        title: "주간 점검 경고",
        reason: reason,
        created_at: date # 월 귀속을 위해 날짜 강제 지정
      )
      # penalty_count는 단순 누적용으로 유지하거나 제거.
      # 여기서는 로직의 일관성을 위해 increment하되, 판정은 monthly counts로 함.
      increment!(:penalty_count)
      status_warned!
      check_kick_condition!
    end

    # 알림 전송
    RoutineClubNotificationService.notify_warning(self, current_month_penalty_count, reason)
  end

  def current_month_penalty_count
    # 현재 월에 귀속된 경고장 개수 (매월 1일 자동 초기화 효과)
    # created_at이 이번 달에 속하는 경고만 카운트
    penalties.where(created_at: Time.current.all_month).count
  end

  def check_kick_condition!
    # 동일한 월 내에서 경고장 3회 누적 시 제명
    if current_month_penalty_count >= 3
      kick!("월간 경고 3회 누적 (자동 제명)")
    end
  end

  # 주간 성과 점검 (매주 월요일 실행)
  def check_weekly_performance!(date = Date.current, dry_run: false)
    return false unless status_active? || status_warned?

    # 1. 평가 대상 주차 확정 (지난주 월요일 ~ 일요일)
    # date가 월요일이면 지난주 전체를 본다.
    last_week_end = date.last_week.end_of_week
    last_week_start = date.last_week.beginning_of_week

    # 2. 월 귀속 기준일 (평가 대상 주차의 "월요일")
    # 규칙: 한 주는 해당 주의 ‘월요일이 속한 월’에 귀속된다.
    attribution_date = last_week_start

    # [신규 회원 평가 시작 규칙]
    # 가입일이 평가 대상 주차의 월요일보다 늦으면 평가 제외 (가입 주차 제외)
    # 단, 가입일이 월요일인 경우 해당 주부터 평가 포함 (joined_at <= attribution_date)
    if joined_at && joined_at.to_date > attribution_date
      return false
    end

    # 3. 중복 실행 방지 (Dry run일 때는 스킵하지 않음)
    # 해당 주차(attribution_date)에 해당하는 경고가 이미 있는지 확인
    unless dry_run
      if penalties.where(created_at: attribution_date.all_day).exists?
        Rails.logger.info "[Skip] User #{user.nickname} already evaluated for week of #{attribution_date}"
        return false
      end
    end

    # 4. 달성률 계산 및 판정
    rate = weekly_routine_rate(last_week_end)

    if rate < 70.0
      if dry_run
        true # 경고 대상임
      else
        # 경고 부여 (귀속일자 기준)
        warn!("주간 루틴 달성률 저조 (#{rate}% < 70%)", attribution_date)
        true
      end
    else
      false
    end
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
      attendance.update!(status: :excused, pass_type: "relax")
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
      attendance.update!(status: :excused, pass_type: "save")
      increment!(:used_save_passes_count)
      update_attendance_stats!
    end
    true
  end

  def recalculate_growth_points!
    # Points logic:
    # 1. 10 pts per present day (기본 출석)
    # 2. Bonus for routine achievement:
    #    - 100% achievement: +30 pts bonus
    #    - 50-99% achievement: +5 pts bonus
    # 3. 50 pts Golden Fire bonus (per 7-day perfect streak)

    points = 0
    attendances_data = attendances.where(status: :present)

    # 1. Base Attendance
    points += attendances_data.count * 10

    # 2. Achievement Bonuses
    attendances_data.each do |a|
      if a.achievement_rate.to_f >= 100.0
        points += 30 # 밸런스 조정: 20 -> 30
      elsif a.achievement_rate.to_f >= 50.0
        points += 5
      end
    end

    # 3. Golden Fire (7-day streaks)
    points += (attendances_data.count / 7) * 50 # 밸런스 조정: 20 -> 50

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

  # 주간 달성률 계산 (월~일 전체 기간 기준)
  def weekly_attendance_rate(date = Date.current)
    start_date = date.beginning_of_week
    end_date = date.end_of_week
    calculate_period_rate(start_date, end_date)
  end

  # 월간 달성률 계산 (1일~말일 전체 기간 기준)
  def monthly_attendance_rate(date = Date.current)
    start_date = date.beginning_of_month
    end_date = date.end_of_month
    calculate_period_rate(start_date, end_date)
  end

  # 주간 루틴 수행률 계산 (루틴 개수 기준)
  def weekly_routine_rate(date = Date.current)
    start_date = date.beginning_of_week
    # 미래의 날짜는 모수에 포함하지 않음 (오늘까지만 계산)
    end_date = [ date.end_of_week, Date.current ].min
    calculate_routine_rate(start_date, end_date)
  end

  # 월간 루틴 수행률 계산 (루틴 개수 기준)
  def monthly_routine_rate(date = Date.current)
    start_date = date.beginning_of_month
    # 미래의 날짜는 모수에 포함하지 않음 (오늘까지만 계산)
    end_date = [ date.end_of_month, Date.current ].min
    calculate_routine_rate(start_date, end_date)
  end

  def performance_stats(start_date, end_date)
    # [Fix] 루틴 유효성(생성일, 삭제일)과 완료 기록을 일별로 정확히 대조하여 계산
    all_routines = user.personal_routines.to_a
    completions = PersonalRoutineCompletion
                   .where(personal_routine_id: all_routines.map(&:id))
                   .where(completed_on: start_date..end_date)
                   .to_a
                   .group_by(&:completed_on)

    # 해당 기간 내 패스(휴식/세이브)를 사용한 기록들
    excused_attendances = attendances.where(attendance_date: start_date..end_date, status: :excused)
    excused_dates = excused_attendances.pluck(:attendance_date)

    # 패스 종류별 카운트
    # [Note] pass_type 컬럼이 없는 기존 기록은 일단 구분 불가 (all 'relax' or 'unknown'으로 보일 수 있음)
    relax_count = excused_attendances.where(pass_type: "relax").count
    save_count = excused_attendances.where(pass_type: "save").count
    unknown_count = excused_attendances.where(pass_type: [ nil, "" ]).count

    total_required = 0
    total_completed = 0

    (start_date..end_date).each do |date|
      routines_on_day = all_routines.select do |r|
        days_list = r.days
        if days_list.is_a?(String)
          begin
            days_list = JSON.parse(days_list)
          rescue JSON::ParserError
            days_list = []
          end
        end
        is_scheduled = (days_list || []).include?(date.wday.to_s)
        is_alive = r.created_at.to_date <= date && (r.deleted_at.nil? || r.deleted_at.to_date > date)
        is_scheduled && is_alive
      end

      day_count = routines_on_day.size
      total_required += day_count

      if excused_dates.include?(date)
        total_completed += day_count
      else
        active_routine_ids = routines_on_day.map(&:id)
        day_completions = completions[date] || []
        actual_day_completed = day_completions.count { |c| active_routine_ids.include?(c.personal_routine_id) }
        total_completed += actual_day_completed
      end
    end

    rate = total_required == 0 ? 0.0 : (total_completed.to_f / total_required * 100).round(1)
    {
      total_required: total_required,
      total_completed: total_completed,
      rate: [ rate, 100.0 ].min,
      relax_count: relax_count,
      save_count: save_count,
      unknown_pass_count: unknown_count
    }
  end

  def routines_needed_for_70_percent(start_date, end_date)
    stats = performance_stats(start_date, end_date)
    target = (stats[:total_required] * 0.7).ceil
    [ target - stats[:total_completed], 0 ].max
  end

  private

  def calculate_routine_rate(start_date, end_date)
    stats = performance_stats(start_date, end_date)
    stats[:rate]
  end

  def calculate_period_rate(start_date, end_date)
    # [Fix] 출석률 또한 해당 일에 실제 '해야 할 루틴'이 있었는지 일별로 체크하여 계산
    all_routines = user.personal_routines.to_a
    attendance_map = attendances.where(attendance_date: start_date..end_date).index_by(&:attendance_date)

    total_target_days = 0
    actual_attendance_count = 0

    (start_date..end_date).each do |date|
      # 해당 일자에 유효했던(살아있었던) 루틴이 하나라도 있는지 확인
      has_active_routine = all_routines.any? do |r|
        days_list = r.days
        if days_list.is_a?(String)
          begin
            days_list = JSON.parse(days_list)
          rescue JSON::ParserError
            days_list = []
          end
        end
        is_scheduled = (days_list || []).include?(date.wday.to_s)
        is_alive = r.created_at.to_date <= date && (r.deleted_at.nil? || r.deleted_at.to_date > date)

        is_scheduled && is_alive
      end

      if has_active_routine
        total_target_days += 1
        att = attendance_map[date]
        if att && (att.status_present? || att.status_excused?)
          actual_attendance_count += 1
        end
      end
    end

    return 0.0 if total_target_days == 0

    rate = (actual_attendance_count.to_f / total_target_days * 100).round(1)
    [ rate, 100.0 ].min
  end


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

  def award_season_badge
    # TODO: 기수별로 동적으로 뱃지를 찾도록 개선 가능 (예: routine_club.title 파싱)
    # 현재는 7기 뱃지 하드코딩 (이름에 '7기'가 포함된 클럽 멤버십 뱃지)

    target_badge_name = "루파 클럽 7기 멤버"
    badge = Badge.find_by(badge_type: :club_membership, name: target_badge_name)

    return unless badge

    # 이미 뱃지가 있는지 확인 후 지급
    unless user.badges.exists?(id: badge.id)
      UserBadge.create!(
        user: user,
        badge: badge,
        acquired_at: Time.current
      )

      # 뱃지 획득 알림 (선택 사항)
      # Notification.create(user: user, title: "뱃지 획득!", message: "#{badge.name} 뱃지를 획득하셨습니다.", ...)
    end
  end
end
