class RankingsController < ApplicationController
  def index
    @weekly_rankings = weekly_ranking_data
    @hall_of_fame = hall_of_fame_data
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
        .order("weekly_count DESC")
        .limit(20)
  end

  def hall_of_fame_data
    User.joins(participations: :verification_logs)
        .where(verification_logs: { status: :approved })
        .group("users.id")
        .select("users.*, COUNT(verification_logs.id) as total_count")
        .order("total_count DESC")
        .limit(20)
  end
end
