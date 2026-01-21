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
      received_cheers: @current_user.rufa_claps.count, # Simplified: claps on your activities
      sent_cheers: @current_user.rufa_claps.count,
      best_routine_count: @current_user.personal_routines.where("current_streak >= 7").count,
      rating: @current_user.reviews.average(:rating) || 5.0
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

    # Contextual Motivation (Dynamic but encouraging)
    @inspiration_count = [ User.active.count / 10, 5 ].max
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
