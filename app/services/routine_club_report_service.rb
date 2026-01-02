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
    # 지난달 1일 ~ 말일 (현재 테스트를 위해 이번달 리포트를 생성할 수 있게 유연하게 처리)
    start_date = 1.month.ago.beginning_of_month.to_date
    end_date = 1.month.ago.end_of_month.to_date

    RoutineClub.active_clubs.find_each do |club|
      club.members.confirmed.find_each do |membership|
        create_report(membership, :monthly, start_date, end_date)
      end
    end
  end

  private

  def self.create_report(membership, type, start_date, end_date)
    user = membership.user

    # 이미 생성된 리포트가 있는지 확인
    return if RoutineClubReport.exists?(
      routine_club: membership.routine_club,
      user: user,
      report_type: type,
      start_date: start_date
    )

    # 루파 전용 지표 계산
    log_rate = user.monthly_routine_log_rate(start_date)
    achievement_rate = user.monthly_achievement_rate(start_date)

    # 정체성(Identity) 타이틀 부여
    identity_title = determine_identity(log_rate, achievement_rate)
    membership.update(identity_title: identity_title)

    # 메시지 생성
    summary = generate_rufa_summary(user, log_rate, achievement_rate, identity_title)
    cheering_message = generate_rufa_cheering(achievement_rate)

    RoutineClubReport.create!(
      routine_club: membership.routine_club,
      user: user,
      report_type: type,
      start_date: start_date,
      end_date: end_date,
      log_rate: log_rate,
      achievement_rate: achievement_rate,
      identity_title: identity_title,
      summary: summary,
      cheering_message: cheering_message,
      attendance_rate: achievement_rate # 호환성을 위해 유지
    )
  end

  def self.determine_identity(log_rate, achievement_rate)
    score = (log_rate + achievement_rate) / 2
    case
    when score >= 90 then "루파 로드 마스터 (Rufa Road Master)"
    when score >= 70 then "정진하는 가이드 (Determined Guide)"
    when score >= 40 then "성장의 개척자 (Growth Pioneer)"
    else "시작하는 파인더 (Beginning Finder)"
    end
  end

  def self.generate_rufa_summary(user, log_rate, achievement_rate, identity)
    goals = user.user_goals.index_by(&:goal_type)
    long_term = goals["long_term"]&.body || "원대한 꿈"

    status_msg = if achievement_rate >= 70
      "놀랍습니다! 루파 클럽의 엄격한 기준(70%)을 훌륭히 통과하셨습니다."
    else
      "아쉽게도 이번 달은 루파 클럽 유지 기준(70%)에 조금 미치지 못했습니다."
    end

    "#{user.nickname}님은 현재 '#{identity}'로서 '#{long_term}'을(를) 향해 나아가고 있습니다. " \
    "기록률 #{log_rate}%, 달성률 #{achievement_rate}%를 기록하셨네요. #{status_msg}"
  end

  def self.generate_rufa_cheering(rate)
    if rate >= 70
      "✨ 꾸준함이 무기가 되는 순간을 목격하고 있습니다. 다음 달도 당신의 성장을 응원합니다!"
    else
      "💪 흔들릴 수 있습니다. 하지만 루파 클럽이 성장의 기준점이 되어 드릴게요. 다시 시작해봐요!"
    end
  end
end
