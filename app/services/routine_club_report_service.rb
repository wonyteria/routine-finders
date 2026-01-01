# frozen_string_literal: true

class RoutineClubReportService
  def self.generate_weekly_reports
    # 지난주 월요일 ~ 일요일
    start_date = 1.week.ago.beginning_of_week.to_date
    end_date = 1.week.ago.end_of_week.to_date

    RoutineClub.active_clubs.find_each do |club|
      club.members.where(payment_status: :confirmed).find_each do |membership|
        create_report(membership, :weekly, start_date, end_date)
      end
    end
  end

  def self.generate_monthly_reports
    # 지난달 1일 ~ 말일
    start_date = 1.month.ago.beginning_of_month.to_date
    end_date = 1.month.ago.end_of_month.to_date

    RoutineClub.active_clubs.find_each do |club|
      club.members.where(payment_status: :confirmed).find_each do |membership|
        create_report(membership, :monthly, start_date, end_date)
      end
    end
  end

  private

  def self.create_report(membership, type, start_date, end_date)
    # 이미 생성된 리포트가 있는지 확인
    return if RoutineClubReport.exists?(
      routine_club: membership.routine_club,
      user: membership.user,
      report_type: type,
      start_date: start_date
    )

    # 통계 계산
    attendances = membership.attendances.where(attendance_date: start_date..end_date)
    attendance_count = attendances.status_present.count
    absence_count = attendances.status_absent.count
    received_cheers_count = attendances.sum(:cheers_count)

    # 총 일수 (주말 포함 여부 등은 클럽 설정에 따를 수 있으나 단순화를 위해 기간 전체로 계산)
    total_days = (end_date - start_date).to_i + 1
    attendance_rate = (attendance_count.to_f / total_days * 100).round(1)

    # 메시지 생성
    summary = generate_summary(type, attendance_rate, attendance_count)
    cheering_message = generate_cheering_message(attendance_rate)

    RoutineClubReport.create!(
      routine_club: membership.routine_club,
      user: membership.user,
      report_type: type,
      start_date: start_date,
      end_date: end_date,
      attendance_count: attendance_count,
      absence_count: absence_count,
      received_cheers_count: received_cheers_count,
      attendance_rate: attendance_rate,
      summary: summary,
      cheering_message: cheering_message
    )
  end

  def self.generate_summary(type, rate, count)
    period = type == :weekly ? "지난주" : "지난달"

    if rate >= 90
      "#{period} #{count}일 출석으로 완벽에 가까운 루틴을 실천하셨네요! 정말 대단합니다."
    elsif rate >= 70
      "#{period} #{count}일 출석하셨습니다. 꾸준함이 돋보이는 한 주였어요."
    elsif rate >= 40
      "#{period} #{count}일 출석하셨습니다. 조금 더 분발해볼까요?"
    else
      "#{period} 출석이 조금 저조했습니다. 이번 기간에는 더 힘내봐요!"
    end
  end

  def self.generate_cheering_message(rate)
    if rate >= 90
      "🔥 이 기세 그대로! 당신은 루틴 마스터입니다."
    elsif rate >= 70
      "👏 아주 잘하고 있어요. 꾸준함이 답이다!"
    elsif rate >= 40
      "💪 시작이 반입니다. 포기하지 말고 끝까지 함께해요."
    else
      "✨ 괜찮아요. 오늘은 새로운 시작을 위한 준비일 뿐입니다."
    end
  end
end
