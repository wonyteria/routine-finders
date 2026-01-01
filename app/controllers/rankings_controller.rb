class RankingsController < ApplicationController
  def index
    @weekly_rankings = weekly_ranking_data
    @hall_of_fame = hall_of_fame_data
    @badge_rankings = badge_ranking_data

    # Categorized Rankings
    @challenge_rankings = category_ranking_data(entry_type: :season, mode: :online)
    @routine_rankings = routine_ranking_data
    @gathering_rankings = category_ranking_data(mode: :offline)
    @host_rankings = host_ranking_data

    if logged_in?
      @current_user_badges = current_user.badges
      @badges_by_type = Badge.order(level: :asc).all.group_by { |b| b.target_type || "all" }
      @user_badge_ids = current_user.badges.pluck(:id)
      @user_metrics = calculate_user_metrics(current_user)
    end
  end

  private

  def weekly_ranking_data
    # 이번 주 월요일부터 일요일까지
    week_start = Time.current.beginning_of_week
    week_end = Time.current.end_of_week

    User.joins(participations: :verification_logs)
        .where(verification_logs: { status: :approved, created_at: week_start..week_end })
        .group("users.id")
        .select("users.*, COUNT(verification_logs.id) as weekly_count")
        .order(Arel.sql("COUNT(verification_logs.id) DESC"))
        .limit(20)
  end

  def hall_of_fame_data
    User.joins(participations: :verification_logs)
        .where(verification_logs: { status: :approved })
        .group("users.id")
        .select("users.*, COUNT(verification_logs.id) as total_count")
        .order(Arel.sql("COUNT(verification_logs.id) DESC"))
        .limit(20)
  end

  def badge_ranking_data
    User.left_joins(:user_badges)
        .select("users.*, COUNT(user_badges.id) as badge_count")
        .group("users.id")
        .includes(:badges)
        .order(Arel.sql("COUNT(user_badges.id) DESC, users.created_at ASC"))
        .limit(20)
  end

  def category_ranking_data(filters)
    User.joins(participations: :challenge)
        .where(challenges: filters)
        .group("users.id")
        .select("users.*, COUNT(participants.id) as activity_count, AVG(participants.completion_rate) as avg_rate")
        .order(Arel.sql("COUNT(participants.id) DESC"))
        .limit(20)
  end

  def routine_ranking_data
    User.joins(:personal_routines)
        .group("users.id")
        .select("users.*, SUM(personal_routines.total_completions) as total_completions")
        .order(Arel.sql("SUM(personal_routines.total_completions) DESC"))
        .limit(20)
  end

  def host_ranking_data
    User.joins(:hosted_challenges)
        .group("users.id")
        .select("users.*, SUM(challenges.current_participants) as total_hosted_participants, COUNT(challenges.id) as hosted_count")
        .order(Arel.sql("SUM(challenges.current_participants) DESC"))
        .limit(20)
  end

  def calculate_user_metrics(user)
    participations = user.participations
    hosted = user.hosted_challenges
    routines = user.personal_routines
    {
      all: {
        achievement_rate: participations.average(:completion_rate) || 0.0,
        verification_count: VerificationLog.where(participant: participations).count,
        max_streak: participations.maximum(:max_streak) || 0
      },
      challenge: {
        verification_count: VerificationLog.joins(participant: :challenge).where(participants: { user_id: user.id }, challenges: { entry_type: :season, mode: :online }).count
      },
      routine: {
        verification_count: routines.sum(:total_completions)
      },
      gathering: {
        verification_count: VerificationLog.joins(participant: :challenge).where(participants: { user_id: user.id }, challenges: { mode: :offline }).count
      },
      host: {
        host_participants: hosted.sum(:current_participants) || 0,
        host_count: hosted.where(status: :ended).count
      }
    }
  end
end
