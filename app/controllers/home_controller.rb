# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @current_user = current_user
    if @current_user
      @main_banners = Banner.banner_type_main.active.ordered
      @ad_banners = Banner.banner_type_ad.active.ordered
      @pick_challenges = Challenge.online_challenges.where(is_featured: true).order(created_at: :desc).limit(6)
      @popular_challenges = Challenge.online_challenges.where(is_featured: [ false, nil ]).order(current_participants: :desc, created_at: :desc).limit(6)
      @recommended_gatherings = Challenge.offline_gatherings.order(created_at: :desc).limit(6)
      @hot_gatherings = Challenge.offline_gatherings.order(current_participants: :desc).limit(6)
      @personal_routines = @current_user&.personal_routines&.includes(:completions) || []
      @participations = @current_user&.participations&.includes(challenge: { participants: :user }) || []
      @my_club_memberships = @current_user.routine_club_members.active.includes(:routine_club)
      set_activity_data

      @total_activities = @activity_data.values.sum

      # Calculate Current Streak
      @current_streak = 0
      check_date = Date.current
      while @activity_data[check_date] > 0
        @current_streak += 1
        check_date -= 1.day
      end

      # Top Badge Achievers for Home
      @top_achievers = User.joins(:user_badges)
                           .select("users.*, COUNT(user_badges.id) as badge_count")
                           .group("users.id")
                           .order("badge_count DESC")
                           .limit(3)

      # Top Hosts for Home - Scoring logic
      # Featured hosts FIRST, then Score = (participants * 0.5) + (avg_completion * 2.0) + (completed_challenges * 10)
      @top_hosts = User.where("host_total_participants > 0 OR host_completed_challenges > 0 OR is_featured_host = ?", true)
                       .select("users.*, (COALESCE(host_total_participants, 0) * 0.5 + COALESCE(host_avg_completion_rate, 0) * 2.0 + COALESCE(host_completed_challenges, 0) * 10) as host_score")
                       .order("is_featured_host DESC, host_score DESC")
                       .limit(4)
    else
      render :landing
    end
  end

  def landing
    # Landing page for both guest and logged-in users who want to see the platform intro
  end

  def pwa_guide
    # PWA usage guide page
  end

  def ranking
    @rankings = User.left_joins(:user_badges)
                    .select("users.*, COUNT(user_badges.id) as badge_count")
                    .group("users.id")
                    .order("badge_count DESC, created_at ASC")
  end

  def host_ranking
    @rankings = User.where("host_total_participants > 0 OR host_completed_challenges > 0 OR is_featured_host = ?", true)
                    .select("users.*, (COALESCE(host_total_participants, 0) * 0.5 + COALESCE(host_avg_completion_rate, 0) * 2.0 + COALESCE(host_completed_challenges, 0) * 10) as host_score")
                    .order("is_featured_host DESC, host_score DESC")
  end

  def user_profile
    @user = User.find(params[:id])
    @participations = @user.participations.includes(:challenge)
    @badges = @user.badges
    @verification_logs = VerificationLog.joins(participant: :user).where(users: { id: @user.id }).recent.limit(20)

    # Growth Summary
    @max_streak = @participations.map(&:max_streak).max || 0
    @total_completed = @user.completed_count
  end

  def achievement_report
    @current_user = current_user
    @participations = @current_user&.participations&.includes(:challenge) || []
    set_activity_data

    # 성장 투자 통계 (My Page와 동일한 로직)
    active_participations = @participations.select { |p| p.challenge.status_active? }
    @growth_stats = {
      total_invested: @participations.sum { |p| p.challenge.amount || 0 },
      total_refunded: @current_user&.total_refunded || 0,
      expected_refund: active_participations.sum { |p| p.challenge.amount || 0 },
      wallet_balance: @current_user&.wallet_balance || 0
    }

    # Social & Support Data
    @social_stats = {
      best_routine_count: @current_user.personal_routines.where("current_streak >= 7").count,
      rating: (@current_user.reviews.average(:rating) || 5.0).round(1)
    }

    # Recent Transactions (Simplified based on participations)
    @recent_transactions = @participations.order(created_at: :desc).limit(5).map do |p|
      {
        title: p.challenge.title,
        date: p.created_at.strftime("%m.%d"),
        amount: p.challenge.amount,
        type: "out",
        color: "slate"
      }
    end

    # Hall of Fame Data
    @top_achievers = User.joins(:user_badges)
                         .select("users.*, COUNT(user_badges.id) as badge_count")
                         .group("users.id")
                         .order("badge_count DESC")
                         .limit(3)

    # Routine Time Stats
    set_routine_time_stats

    # Calculate real Routine Efficiency Score
    # Based on average completion rate of last 7 days + consistency factor
    last_7_days = (0..6).map { |i| Date.current - i.days }
    @efficiency_data = last_7_days.map { |date| @current_user.daily_achievement_rate(date) }.reverse

    # Use Total Routine Rate for accurate weekly performance measurement
    avg_completion = @current_user.period_routine_rate(Date.current - 6.days, Date.current)

    # Consistency factor: points for each day with > 0% completion
    consistency_days = @efficiency_data.count { |v| v > 0 }
    @efficiency_score = (avg_completion * 0.8 + (consistency_days / 7.0 * 100) * 0.2).round(1)

    # Dynamic Peak Time Comment
    peak_hour = @routine_time_stats&.max_by { |k, v| v }&.first
    @efficiency_comment = case peak_hour
    when 5..10 then "아침 시간대 집중력이 아주 높으시네요! 몰입 효율이 대단합니다."
    when 11..16 then "오후 시간에 루틴을 가장 활발하게 처리하고 계시는군요."
    when 17..22 then "저녁 시간을 활용해 하루를 멋지게 마무리하는 타입이시네요."
    else "심야 시간에 집중력이 폭발하는 스타일이시군요!"
    end

    # Contextual Motivation (Dynamic but encouraging)
    @inspiration_count = [ User.active.count / (rand(5..15)), 5 ].max
  end

  def badge_roadmap
    @current_user = current_user
    @badges_by_type = Badge.order(level: :asc).group_by(&:badge_type)
    @user_badge_ids = @current_user&.badges&.pluck(:id) || []
  end

  def mark_badges_viewed
    badge_ids = params[:badge_ids]
    current_user.user_badges.where(id: badge_ids).update_all(is_viewed: true)
    head :ok
  end

  def track_share
    return head :unauthorized unless current_user

    current_user.increment!(:share_count)

    RufaActivity.create!(
      user: current_user,
      activity_type: "share",
      body: "루파 클럽의 성취 에너지를 주변에 공유했습니다! 🔗"
    )

    # Check for share-related badges
    BadgeService.check_share_badges(current_user)

    head :ok
  end

  private

  def set_activity_data
    return unless current_user

    @activity_data = Hash.new(0)

    # Challenge Verifications
    VerificationLog.joins(participant: :user)
                  .where(users: { id: current_user.id })
                  .where(created_at: 1.year.ago..Time.current)
                  .group("DATE(verification_logs.created_at)")
                  .count.each { |date, count| @activity_data[date.to_date] += count }

    # Personal Routine Completions
    PersonalRoutineCompletion.joins(:personal_routine)
                             .where(personal_routines: { user_id: current_user.id })
                             .where(completed_on: 1.year.ago..Date.current)
                             .group(:completed_on)
                             .count.each { |date, count| @activity_data[date] += count }

    # Club Attendances
    RoutineClubAttendance.joins(:routine_club_member)
                         .where(routine_club_members: { user_id: current_user.id })
                         .where(attendance_date: 1.year.ago..Date.current)
                         .group(:attendance_date)
                         .count.each { |date, count| @activity_data[date] += count }

    @monthly_completions = @activity_data.select { |date, _| date >= Date.current.beginning_of_month && date <= Date.current.end_of_month }
  end

  def set_routine_time_stats
    return unless current_user

    # Group completions by hour of creation (completion time)
    @routine_time_stats = PersonalRoutineCompletion.joins(:personal_routine)
                                                     .where(personal_routines: { user_id: current_user.id })
                                                     .group("CAST(strftime('%H', personal_routine_completions.created_at) AS INT)")
                                                     .count

    # Fill in missing hours
    (0..23).each { |h| @routine_time_stats[h] ||= 0 }
  end
end
