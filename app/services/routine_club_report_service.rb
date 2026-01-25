# frozen_string_literal: true

# 루파 클럽 리포트 생성 서비스
# 복잡한 리포트 생성 로직을 컨트롤러에서 분리하여 재사용성과 테스트 가능성 향상
class RoutineClubReportService
  attr_reader :user, :report_type, :start_date, :end_date

  def initialize(user:, report_type:, start_date: nil, end_date: nil)
    @user = user
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
    routines = user.personal_routines
    total_days = (start_date..end_date).count

    # 기록률 계산
    logged_days = routines.flat_map do |routine|
      routine.routine_logs.where(logged_at: start_date..end_date).pluck(:logged_at)
    end.uniq.count

    log_rate = total_days > 0 ? (logged_days.to_f / total_days * 100).round(1) : 0

    # 달성률 계산 (실제 완료한 루틴 비율)
    total_expected = routines.sum do |routine|
      (start_date..end_date).count { |date| (routine.days || []).include?(date.wday.to_s) }
    end

    total_completed = routines.sum do |routine|
      routine.routine_logs.where(logged_at: start_date..end_date, completed: true).count
    end

    achievement_rate = total_expected > 0 ? (total_completed.to_f / total_expected * 100).round(1) : 0

    # 타이틀 결정
    identity_title = determine_identity_title(achievement_rate)

    # 요약 메시지
    summary = generate_summary(log_rate, achievement_rate, total_completed)

    # 응원 메시지
    cheering_message = generate_cheering_message(achievement_rate)

    {
      log_rate: log_rate,
      achievement_rate: achievement_rate,
      identity_title: identity_title,
      summary: summary,
      cheering_message: cheering_message
    }
  end

  def determine_identity_title(achievement_rate)
    case achievement_rate
    when 90..100 then "완벽주의자 🏆"
    when 80...90 then "성실한 루퍼 ⭐"
    when 70...80 then "꾸준한 도전자 💪"
    when 50...70 then "성장하는 루퍼 🌱"
    else "시작하는 루퍼 🌟"
    end
  end

  def generate_summary(log_rate, achievement_rate, completed_count)
    "#{report_type == 'weekly' ? '이번 주' : '이번 달'} 기록률 #{log_rate}%, 달성률 #{achievement_rate}%로 총 #{completed_count}개의 루틴을 완료했습니다."
  end

  def generate_cheering_message(achievement_rate)
    case achievement_rate
    when 90..100
      "놀라운 성과입니다! 이 페이스를 유지하세요! 🎉"
    when 80...90
      "훌륭합니다! 조금만 더 힘내면 완벽해요! 💪"
    when 70...80
      "잘하고 있어요! 꾸준함이 힘입니다! 🌟"
    when 50...70
      "좋은 시작입니다! 계속 도전하세요! 🚀"
    else
      "괜찮아요! 다시 시작하면 됩니다! 화이팅! 💪"
    end
  end
end
