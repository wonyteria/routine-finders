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
    daily_rates = []
    active_days_count = 0
    completions_by_hour = Hash.new(0)
    total_completed_count = 0

    target_period.each do |date|
      # 해당 요일에 수행해야 하는 루틴들
      target_routines_for_day = routines.select { |r| (r.days || []).include?(date.wday.to_s) }

      if target_routines_for_day.any?
        completed_for_day = target_routines_for_day.select { |r| r.completions.exists?(completed_on: date) }
        date_rate = (completed_for_day.count.to_f / target_routines_for_day.count) * 100
        daily_rates << date_rate

        if completed_for_day.any?
          active_days_count += 1
          total_completed_count += completed_for_day.count
          # 시간대 분석 (간단하게 완료 기록의 생성 시간 사용)
          completed_for_day.each do |r|
             # 최적화를 위해 메모리에 로드된 association 사용
             completion = r.completions.find { |c| c.completed_on == date }
             completions_by_hour[completion.created_at.hour] += 1 if completion
          end
        end
      else
        # 목표 루틴이 없는 날은 통계에서 제외 (성취율 평균 깎지 않음)
      end
    end

    # 2. Achievement Rate (효율성 점수): 평균 달성률
    # HomeController 로직: avg_completion * 0.8 + consistency * 0.2
    # 하지만 여기서는 직관적인 '평균 달성률'로 단순화하되, 데이터가 없는 날은 제외하고 계산
    achievement_rate = daily_rates.any? ? (daily_rates.sum / daily_rates.size).round(1) : 0

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
     পেয়েelsif achievement_rate >= 80
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
