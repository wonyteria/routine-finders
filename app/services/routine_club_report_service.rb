# frozen_string_literal: true

# 루파 클럽 리포트 생성 서비스
# 복잡한 리포트 생성 로직을 컨트롤러에서 분리하여 재사용성과 테스트 가능성 향상
class RoutineClubReportService
  attr_reader :user, :routine_club, :report_type, :start_date, :end_date

  def initialize(user:, routine_club:, report_type:, start_date: nil, end_date: nil)
    @user = user
    @routine_club = routine_club
    @report_type = report_type
    @start_date = start_date || calculate_start_date
    @end_date = end_date || Date.current
  end

  # 리포트 생성 또는 조회
  def generate_or_find
    existing_report = find_existing_report
    return existing_report if existing_report

    create_new_report
  end

  # 강제로 새 리포트 생성
  def create_new_report
    report_data = calculate_report_data

    RoutineClubReport.create!(
      user: user,
      routine_club: routine_club,
      report_type: report_type,
      start_date: start_date,
      end_date: end_date,
      log_rate: report_data[:log_rate],
      achievement_rate: report_data[:achievement_rate],
      identity_title: report_data[:identity_title],
      summary: report_data[:summary],
      cheering_message: report_data[:cheering_message]
    )
  end

  private

  def find_existing_report
    RoutineClubReport.find_by(
      user: user,
      routine_club: routine_club,
      report_type: report_type,
      start_date: start_date
    )
  end

  def calculate_start_date
    case report_type
    when "weekly"
      Date.current.beginning_of_week
    when "monthly"
      Date.current.beginning_of_month
    else
      Date.current
    end
  end

  def calculate_report_data
    routines = user.personal_routines.includes(:completions).to_a
    target_period = (start_date..end_date).to_a
    total_days = target_period.count

    # 1. 일별 성취율 계산 및 통계 수집
    active_days_count = 0
    completions_by_hour = Hash.new(0)

    # 새로 추가: 기간 전체 합산 변수 (Total Routine Rate 계산용)
    total_target_count_period = 0
    total_completed_count_period = 0

    member = routine_club.members.find_by(user: user)
    attendance_map = member ? member.attendances.where(attendance_date: start_date..end_date).index_by(&:attendance_date) : {}
    excused_dates = attendance_map.values.select(&:status_excused?).map(&:attendance_date)

    # 루틴 완료 기록 미리 가져오기 (N+1 방지)
    completions = PersonalRoutineCompletion
                   .where(personal_routine_id: routines.map(&:id))
                   .where(completed_on: start_date..end_date)
                   .to_a
                   .group_by(&:completed_on)

    target_period.each do |date|
      # 해당 요일에 수행해야 하는 루틴 중 그날 당시에 유효했던 루틴들만 필터링
      target_routines_for_day = routines.select do |r|
        # 1. 요일 체크
        days_list = r.days
        if days_list.is_a?(String)
          begin
            days_list = JSON.parse(days_list)
          rescue JSON::ParserError
            days_list = []
          end
        end
        is_scheduled = (days_list || []).include?(date.wday.to_s)

        # 2. 유효성 체크 (생성일/삭제일)
        is_alive = r.created_at.to_date <= date && (r.deleted_at.nil? || r.deleted_at.to_date > date)

        is_scheduled && is_alive
      end

      target_count = target_routines_for_day.count
      total_target_count_period += target_count

      if target_count > 0
        # 패스 사용일인 경우 해당 일의 모든 루틴을 완료한 것으로 간주 (Performance Stats와 로직 통일)
        day_completions = completions[date] || []

        if excused_dates.include?(date)
          day_completed_count = target_count
        else
          active_routine_ids = target_routines_for_day.map(&:id)
          day_completed_count = day_completions.count { |c| active_routine_ids.include?(c.personal_routine_id) }
        end

        total_completed_count_period += day_completed_count

        # 성실도(log_rate)를 위한 활동일 카운트: 실제 루틴을 하나라도 했거나 패스를 썼을 때
        if day_completed_count > 0
          active_days_count += 1

          # 시간대 분석 (실제 기록이 있는 경우에만)
          day_completions.each do |completion|
            completions_by_hour[completion.created_at.hour] += 1
          end
        end
      end
    end

    # 2. Achievement Rate (효율성 점수): 기간 전체 '완료 / 목표' 비율 (Total Routine Rate)
    # 기존 평균의 평균 방식에서 '루틴 개수 기반' 정확한 달성률로 변경
    achievement_rate = total_target_count_period > 0 ? (total_completed_count_period.to_f / total_target_count_period * 100).round(1) : 0

    # 3. Log Rate (성실도 점수): 활동일 / 전체 기간 (단, 목표가 있었던 기간 기준이 더 정확할 수 있으나 유저 인식엔 전체 기간이 익숙함)
    # 여기서는 "루틴을 하나라도 수행한 날" 비율로 정의
    log_rate = total_days > 0 ? (active_days_count.to_f / total_days * 100).round(1) : 0

    # 4. Identity Title Deterministic Logic
    identity_title = determine_identity_title(achievement_rate, log_rate)

    # 5. Peak Time Analysis
    peak_hour = completions_by_hour.max_by { |k, v| v }&.first

    # 6. Summary & Cheering
    summary = generate_summary(peak_hour, active_days_count)
    cheering_message = generate_cheering_message(achievement_rate, peak_hour)

    {
      log_rate: log_rate,
      achievement_rate: achievement_rate,
      identity_title: identity_title,
      summary: summary,
      cheering_message: cheering_message
    }
  end

  def determine_identity_title(achievement_rate, log_rate)
    if achievement_rate >= 90 && log_rate >= 90
      "빈틈없는 완벽주의자 👑"
    elsif achievement_rate >= 80
      "성실한 루틴 마스터 ⭐"
    elsif log_rate >= 80
      "끈기있는 개척자 🏃"
    elsif achievement_rate >= 60
      "성장하는 가이드 🌱"
    else
      "잠재력 넘치는 도전자 💎"
    end
  end

  def generate_summary(peak_hour, active_days)
    time_desc = if peak_hour
      case peak_hour
      when 5..10 then "오전 루틴 마스터! 활기찬 시작이 돋보입니다."
      when 11..17 then "오후 집중력 최고! 일과 중에도 꾸준하셨군요."
      when 18..22 then "저녁 시간 관리의 달인! 마무리가 훌륭합니다."
      else "심야의 열정가! 몰입에는 시간이 중요하지 않죠."
      end
    else
      "아직 루틴 패턴을 분석 중입니다."
    end

    "#{time_desc} 총 #{active_days}일 동안 루틴을 실천하며 성장의 발판을 마련했습니다."
  end

  def generate_cheering_message(achievement_rate, peak_hour)
    if achievement_rate >= 90
      "놀라운 몰입도입니다! 당신의 한계는 없습니다. 🚀"
    elsif achievement_rate >= 70
      "아주 좋은 흐름이에요. 이 꾸준함이 비범함을 만듭니다. 💪"
    elsif peak_hour && peak_hour < 10
      "일찍 일어나는 새가 성공을 잡습니다! 아침 루틴 파이팅! ☀️"
    else
      "작은 실천이 모여 위대한 변화를 만듭니다. 오늘도 응원해요! ✨"
    end
  end
end
