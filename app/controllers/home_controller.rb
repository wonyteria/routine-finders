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
      set_activity_data

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
      total_invested: @participations.sum { |p| p.challenge.total_payment_amount || 0 },
      total_refunded: @current_user&.total_refunded || 0,
      expected_refund: active_participations.sum { |p| p.challenge.amount || 0 }
    }
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
end
