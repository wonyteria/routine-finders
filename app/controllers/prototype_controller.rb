class PrototypeController < ApplicationController
  require "ostruct"
  include PrototypeErrorHandler

  layout "prototype"
  before_action :set_shared_data
  before_action :require_login, only: [ :my, :routine_builder, :challenge_builder, :gathering_builder, :club_join, :record, :notifications, :clear_notifications, :pwa, :admin_dashboard, :club_management, :member_reports, :batch_reports ]
  before_action :require_admin, only: [ :admin_dashboard, :club_management, :member_reports, :batch_reports ]
  before_action :require_super_admin, only: [ :broadcast, :update_user_role, :update_user_status, :approve_challenge, :purge_cache, :reset_users ]
  before_action :require_can_create_challenge, only: [ :challenge_builder ]
  before_action :require_can_create_gathering, only: [ :gathering_builder ]

  def login
    @hide_nav = true
  end

  def home
    # 1. Permission & Membership
    @permission = PermissionService.new(current_user)
    @official_club = RoutineClub.official.first
    @my_membership = current_user&.routine_club_members&.confirmed&.find_by(routine_club: @official_club)
    @is_club_member = @permission.is_premium_member?

    # Check for newly approved members who haven't seen the welcome popup
    if @my_membership && @my_membership.payment_status_confirmed? && !@my_membership.welcomed?
      @show_club_welcome_modal = true
      @routine_club = @official_club
    end

    # 2. Routine & Task Progress (Real data)
    @todays_routines = current_user ? current_user.personal_routines.select { |r| (r.days || []).include?(Date.current.wday.to_s) } : []
    @joined_participations = current_user ? current_user.participations.active.joins(:challenge) : Participant.none

    # Progress Calculation
    routine_total = @todays_routines.count
    participation_total = @joined_participations.count
    @total_task_count = routine_total + participation_total

    routine_done = @todays_routines.select(&:completed_today?).count
    participation_done = current_user ? VerificationLog.where(participant: @joined_participations, created_at: Date.current.all_day).pluck(:participant_id).uniq.count : 0
    @completed_count = routine_done + participation_done

    @progress = @total_task_count.positive? ? (@completed_count.to_f / @total_task_count * 100).to_i : 0

    # Unified tasks for Aura visualization
    @aura_tasks = @todays_routines.map do |r|
      { id: "routine_#{r.id}", icon: r.icon, title: r.title, completed: r.completed_today? }
    end
    @aura_tasks += @joined_participations.map do |p|
      icon = case p.challenge.category
      when "HEALTH" then "🏋️"
      when "STUDY" then "📚"
      when "SNS" then "📱"
      when "MONEY" then "💰"
      when "HOBBY" then "🎨"
      when "MIND" then "🧘"
      else "🏆"
      end
      { id: "participation_#{p.id}", icon: icon, title: p.challenge.title, completed: p.verification_logs.where(created_at: Date.current.all_day).exists? }
    end

    # 3. Synergy & Feed
    @rufa_activities = RufaActivity.includes(:user).recent.limit(10)
    @recent_reflections = @rufa_activities.where(activity_type: [ "routine_record", "reflection" ])

    # 4. Global Stats & Benchmark
    @orbit_users = User.joins(:rufa_activities)
                       .where(rufa_activities: { created_at: Date.current.all_day })
                       .where.not(id: current_user&.id)
                       .distinct
                       .limit(100)

    # Calculate Global Average Achievement from actual club member data
    @global_average_progress = Rails.cache.fetch("global_avg_progress_#{Date.current}", expires_in: 30.minutes) do
      avg = RoutineClubMember.where(status: :active, payment_status: :confirmed).average(:attendance_rate)
      avg&.round(1) || 0
    end

    @total_active_metes = User.joins(:rufa_activities)
                              .where("rufa_activities.created_at >= ?", 30.minutes.ago)
                              .distinct.count
    @total_active_metes = [ @total_active_metes, @orbit_users.count ].max

    # 5. Specialized Content (Ranking & Goals) - Use minimal calculation
    @rufa_rankings = Rails.cache.fetch("home_rankings_stable", expires_in: 1.hour) do
      User.joins(:routine_club_members)
          .where(routine_club_members: { status: :active, payment_status: :confirmed })
          .limit(10)
          .map { |u| { user: u, score: u.rufa_club_score } }
          .sort_by { |r| -r[:score] } rescue []
    end
    @top_rankings = (@rufa_rankings || []).take(3)

    if current_user
      @hosted_challenges = Challenge.where(host: current_user).order(created_at: :desc)
      @joined_challenges = current_user.challenges.active.where.not(id: @hosted_challenges.pluck(:id))
      @user_goals = current_user.user_goals.index_by(&:goal_type)
      @short_term_goal = @user_goals["short_term"]&.body
      @mid_term_goal = @user_goals["mid_term"]&.body
      @long_term_goal = @user_goals["long_term"]&.body
      @weekly_goal = current_user.weekly_goal
    else
      @hosted_challenges = []
      @joined_challenges = []
    end
  end

  def explore
    @featured_club = RoutineClub.active_clubs.includes(:host).order(created_at: :desc).first
    @tab_type = params[:type] || "all"
    @sort_type = params[:sort] || "recent"

    # 1. Closing Soon (Recruitment ends within 3 days) - with eager loading
    @closing_soon = Challenge.includes(:host, :participants)
                            .where("recruitment_end_date >= ? AND recruitment_end_date <= ?", Date.current, Date.current + 3.days)
                            .order(:recruitment_end_date).limit(5)

    # 2. Base Queries with eager loading
    challenges_query = Challenge.includes(:host, :participants).where("end_date >= ?", Date.current)
    gatherings_query = Challenge.includes(:host, :participants).where("end_date >= ?", Date.current).where.not(meeting_type: nil)

    # 3. Apply Sorting
    order_clause = case @sort_type
    when "popular"
                     { current_participants: :desc }
    when "amount"
                     { amount: :desc }
    else
                     { created_at: :desc }
    end

    @active_challenges = challenges_query.order(order_clause).limit(6).to_a
    @gatherings = gatherings_query.order(order_clause).limit(6).to_a
  end

  def synergy
    # Hall of Fame: Rank active users, but prioritize RUFA Club members
    # We include users who have recent activities or are club members
    active_activity_user_ids = RufaActivity.where("created_at >= ?", 7.days.ago).pluck(:user_id)
    # Include both active club members AND admins in the club badge logic
    club_member_user_ids = User.joins(:routine_club_members).where(routine_club_members: { status: :active, payment_status: :confirmed }).pluck(:id)
    admin_user_ids = User.admin.pluck(:id)
    all_club_ids = (club_member_user_ids + admin_user_ids).uniq

    relevant_users = User.where(id: (active_activity_user_ids + all_club_ids).uniq)

    @monthly_rankings = relevant_users.map { |u|
      {
        user: u,
        score: u.rufa_club_score,
        is_club: all_club_ids.include?(u.id)
      }
    }.sort_by { |r| -r[:score] }

    if params[:rank_type] == "club"
      @monthly_rankings = @monthly_rankings.select { |r| r[:is_club] }
    end

    @monthly_rankings = @monthly_rankings.take(500)

    # Find my ranking
    @my_ranking = nil
    if current_user
      my_rank_index = @monthly_rankings.index { |r| r[:user].id == current_user.id }
      if my_rank_index
        @my_ranking = {
          rank: my_rank_index + 1,
          score: @monthly_rankings[my_rank_index][:score],
          is_club: @monthly_rankings[my_rank_index][:is_club]
        }
      end
    end

    @top_users = @monthly_rankings.take(3).map { |r| r[:user] }

    # Show only today's activities for live stream
    @recent_activities = RufaActivity.joins(:user)
                                     .where(users: { deleted_at: nil })
                                     .where(created_at: Date.current.all_day)
                                     .order(created_at: :desc)
  end

  def my
    @total_activities = current_user&.total_routine_completions || 0
    @current_streak = current_user&.personal_routines&.maximum(:current_streak) || 0
    @current_month_points = current_user&.current_month_points || 0
    @total_platform_score = current_user&.total_platform_score || 0
    @achievements = current_user&.user_badges&.includes(:badge)&.limit(10) || []

    if current_user
      # Calculate progress for next milestones
      @milestones = []

      # 1. Verification Count (Routine)
      current_verifications = current_user.personal_routines.joins(:completions).count
      next_v_badge = Badge.where(badge_type: :verification_count)
                          .where("requirement_value > ?", current_verifications)
                          .order(requirement_value: :asc).first
      if next_v_badge
        @milestones << {
          name: next_v_badge.name,
          icon: "💎",
          current: current_verifications,
          target: next_v_badge.requirement_value.to_i,
          unit: "회"
        }
      end

      # 2. Max Streak
      max_streak = current_user.personal_routines.maximum(:current_streak) || 0
      next_s_badge = Badge.where(badge_type: :max_streak)
                          .where("requirement_value > ?", max_streak)
                          .order(requirement_value: :asc).first
      if next_s_badge
        @milestones << {
          name: next_s_badge.name,
          icon: "🔥",
          current: max_streak,
          target: next_s_badge.requirement_value.to_i,
          unit: "일"
        }
      end

      # 3. Cheer Count
      current_cheers = current_user.rufa_claps.count
      next_c_badge = Badge.where(badge_type: :cheer_count)
                          .where("requirement_value > ?", current_cheers)
                          .order(requirement_value: :asc).first
      if next_c_badge
        @milestones << {
          name: next_c_badge.name,
          icon: "👏",
          current: current_cheers,
          target: next_c_badge.requirement_value.to_i,
          unit: "회"
        }
      end

      # 4. Challenge Participation
      current_challenges = current_user.participations.count
      next_ch_badge = Badge.participation_count.where("requirement_value > ?", current_challenges)
                           .order(requirement_value: :asc).first
      if next_ch_badge
        @milestones << {
          name: next_ch_badge.name,
          icon: "🏃",
          current: current_challenges,
          target: next_ch_badge.requirement_value.to_i,
          unit: "개"
        }
      end

      # 5. Hosting Count
      current_hosted = current_user.challenges.count
      next_h_badge = Badge.where(badge_type: :host_count)
                          .where("requirement_value > ?", current_hosted)
                          .order(requirement_value: :asc).first
      if next_h_badge
        @milestones << {
          name: next_h_badge.name,
          icon: "👑",
          current: current_hosted,
          target: next_h_badge.requirement_value.to_i,
          unit: "개"
        }
      end

    # 4. Growth Analytics (Real Data)
    # Weekly: Last 7 days completion rate
    @weekly_labels = []
    @weekly_data = (0..6).map do |days_ago|
      date = Date.current - days_ago.days
      @weekly_labels << date.strftime("%m/%d")
      routines = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
      total = routines.count
      completed = routines.select { |r| r.completions.exists?(completed_on: date) }.count
      total.positive? ? ((completed.to_f / total) * 100).round : 0
    end.reverse
    @weekly_labels.reverse!

  # Monthly: Last 4 weeks completion rate (average of daily rates)
  @monthly_labels = []
  @monthly_data = (0..3).map do |weeks_ago|
    week_start = Date.current.beginning_of_week - weeks_ago.weeks
    week_of_month = ((week_start.day - 1) / 7) + 1
    @monthly_labels << "#{week_start.month}월 #{week_of_month}주"

    week_end = week_start + 6.days
    daily_rates = []

    (week_start..week_end).each do |date|
      routines = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
      next if routines.empty?

      total = routines.count
      completed = routines.select { |r| r.completions.exists?(completed_on: date) }.count
      daily_rates << ((completed.to_f / total) * 100).round
    end

    daily_rates.any? ? (daily_rates.sum.to_f / daily_rates.size).round : 0
  end.reverse
  @monthly_labels.reverse!

  # Yearly: This year's monthly completion rates (average of daily rates)
  current_month = Date.current.month
  @yearly_labels = []
  @yearly_data = (1..current_month).map do |month|
    @yearly_labels << "#{month}월"
    month_start = Date.new(Date.current.year, month, 1)
    month_end = [ month_start.end_of_month, Date.current ].min

    daily_rates = []

    (month_start..month_end).each do |date|
      routines = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
      next if routines.empty?

      total = routines.count
      completed = routines.select { |r| r.completions.exists?(completed_on: date) }.count
      daily_rates << ((completed.to_f / total) * 100).round
    end

    daily_rates.any? ? (daily_rates.sum.to_f / daily_rates.size).round : 0
  end

    # Summaries
    @weekly_completion = @weekly_data.last || 0
    @weekly_growth = @weekly_data.size >= 2 ? (@weekly_data[-1] - @weekly_data[-2]) : 0

    @monthly_completion = @monthly_data.last || 0
    @monthly_growth = @monthly_data.size >= 2 ? (@monthly_data[-1] - @monthly_data[-2]) : 0

    @yearly_completion = @yearly_data.last || 0
    @yearly_growth = @yearly_data.size >= 2 ? (@yearly_data[-1] - @yearly_data[-2]) : 0
    end
  end

  def notifications
    @notifications = current_user.notifications.order(created_at: :desc).limit(50)
    # Mark as read concurrently (or just mark all if entering this page)
    current_user.notifications.where(is_read: false).update_all(is_read: true)
  end

  def clear_notifications
    current_user.notifications.destroy_all
    session[:notifications_cleared] = true
    redirect_to prototype_notifications_path, notice: "모든 알림을 삭제했습니다."
  end

  def pwa
  end

  def record
    if current_user && params[:body].present?
      activity_type = params[:activity_type] || "routine_record"
      RufaActivity.create!(
        user: current_user,
        activity_type: activity_type,
        body: params[:body]
      )

      msg = activity_type == "reflection" ? "오늘의 다짐을 선언했습니다! 멋진 하루 보내세요." : "오늘의 루틴 성취를 기록했습니다!"
      redirect_to prototype_home_path, notice: msg
    else
      redirect_to prototype_login_path, alert: "로그인이 필요합니다."
    end
  end

  def routine_builder
    @routine = PersonalRoutine.new
    @categories = [
      { key: "HEALTH", label: "건강/운동" },
      { key: "LIFE", label: "생활/일기" },
      { key: "MIND", label: "마음챙김" },
      { key: "HOBBY", label: "취미/여가" },
      { key: "STUDY", label: "학습/성장" },
      { key: "MONEY", label: "자산/금융" }
    ]
    @icons = [ "✨", "🔥", "🏋️", "📚", "🧘", "📝", "💧", "🏃", "🥗", "💡", "⏰", "🎯", "🧠", "💰", "☀️" ]
  end

  def routine_editor
    @routine = current_user.personal_routines.find(params[:id])
    @categories = [
      { key: "HEALTH", label: "건강/운동" },
      { key: "LIFE", label: "생활/일기" },
      { key: "MIND", label: "마음챙김" },
      { key: "HOBBY", label: "취미/여가" },
      { key: "STUDY", label: "학습/성장" },
      { key: "MONEY", label: "자산/금융" }
    ]
    @icons = [ "✨", "🔥", "🏋️", "📚", "🧘", "📝", "💧", "🏃", "🥗", "💡", "⏰", "🎯", "🧠", "💰", "☀️" ]
  end

  def routines
    @routines = current_user&.personal_routines || []
    render layout: "prototype"
  end

  def live
    @current_club = RoutineClub.official.first
    @active_members = User.order("RANDOM()").limit(22) # Active in the orbit

    # Collective Data for RUFA Club
    @confirmed_members = @current_club&.members&.where(payment_status: :confirmed) || []
    @club_total_members_count = @confirmed_members.count || 42  # Dummy if empty

    # Weekly completion stats (summing members' record counts)
    @club_weekly_completions = (@confirmed_members.sum { |m| m.user.total_routine_completions % 100 } + 4200) # Base + random offset for proto
    @club_temperature = 98.6 # High energy

    @club_announcements = @current_club&.announcements&.order(created_at: :desc)&.limit(2) || []
    @is_club_member = current_user&.is_rufa_club_member?
    unless @is_club_member
      flash[:is_rufa_pending] = true if current_user&.is_rufa_pending?
      redirect_to guide_routine_clubs_path(source: "prototype"), alert: "라운지 입장은 루파 클럽 멤버 전용 혜택입니다." and return
    end
  end

  def lecture_intro
    @hide_nav = true
    @is_club_member = current_user&.is_rufa_club_member?
    unless @is_club_member
      flash[:is_rufa_pending] = true if current_user&.is_rufa_pending?
      redirect_to guide_routine_clubs_path(source: "prototype"), alert: "강의 시청은 루파 클럽 멤버 전용 혜택입니다." and return
    end
    @lecture = {
      title: "성공하는 리더들의 '회복 탄력성' 강화 전략",
      instructor: "이수진 (MINDSET Lab 대표)",
      time: "오늘 오후 8:00 - 9:00",
      description: "오늘의 강의에서는 예기치 못한 실패와 스트레스 상황에서도 다시 일어설 수 있는 '회복 탄력성'을 기르는 3가지 핵심 기술을 배웁니다. 루파클럽 멤버들만을 위해 준비된 특별한 인사이트를 놓치지 마세요.",
      curriculum: [
        "1단계: 내 마음의 상태 객관화하기",
        "2단계: 부정적 편향을 깨는 인지 재구조화",
        "3단계: 일상에서 실천하는 회복 탄력성 루틴"
      ],
      benefits: [
        "강의 요약 PDF 리포트 제공",
        "실시간 Q&A 세션 참여",
        "회복 탄력성 자가진단 툴킷"
      ]
    }
  end

  def hub
  end

  def challenge_builder
    @challenge = Challenge.new
    @categories = [
      { key: "HEALTH", label: "건강·운동", icon: "🏋️" },
      { key: "STUDY", label: "학습·자기계발", icon: "📚" },
      { key: "SNS", label: "SNS·브랜딩", icon: "📱" },
      { key: "MONEY", label: "재테크·부업", icon: "💰" },
      { key: "HOBBY", label: "취미·라이프", icon: "🎨" },
      { key: "MIND", label: "멘탈·성찰", icon: "🧘" }
    ]
    @banks = [ "신한", "국민", "우리", "하나", "농협", "카카오뱅크", "토스뱅크" ]
    @verification_types = [
      { key: "photo", label: "사진 인증", icon: "📸", desc: "실시간 촬영" },
      { key: "simple", label: "간편 인증", icon: "✅", desc: "원클릭 체크" },
      { key: "metric", label: "수치 기록", icon: "📊", desc: "숫자로 기록" },
      { key: "url", label: "링크 제출", icon: "🔗", desc: "활동 로그" }
    ]
  end

  def gathering_builder
    @gathering = Challenge.new(mode: :offline)
    @gathering.build_meeting_info
    @categories = [
      { key: "HEALTH", label: "건강·운동", icon: "🏋️" },
      { key: "STUDY", label: "학습·자기계발", icon: "📚" },
      { key: "SNS", label: "SNS·브랜딩", icon: "📱" },
      { key: "MONEY", label: "재테크·부업", icon: "💰" },
      { key: "HOBBY", label: "취미·라이프", icon: "🎨" },
      { key: "MIND", label: "멘탈·성찰", icon: "🧘" }
    ]
    @banks = [ "신한", "국민", "우리", "하나", "농협", "카카오뱅크", "토스뱅크" ]
  end

  def club_join
    # Ensure we load the official club first to reflect admin settings
    @routine_club = RoutineClub.official.first || RoutineClub.order(created_at: :desc).first
    # Force dates for 7th generation prototype if needed
    if @routine_club && @routine_club.generation_number == 7
      @routine_club.start_date = Date.new(2026, 1, 1)
      @routine_club.end_date = Date.new(2026, 3, 31)
    end
    @is_member = current_user&.routine_club_members&.exists?(routine_club: @routine_club, status: :active)
  end

  def mark_badges_viewed
    current_user&.user_badges&.where(is_viewed: false)&.update_all(is_viewed: true)
    head :ok
  end

  def update_goals
    if current_user
      current_user.update(
        weekly_goal: params[:weekly_goal],
        monthly_goal: params[:monthly_goal],
        yearly_goal: params[:yearly_goal],
        weekly_goal_updated_at: Time.current,
        monthly_goal_updated_at: Time.current,
        yearly_goal_updated_at: Time.current
      )
      redirect_to prototype_my_path, notice: "목표가 성공적으로 저장되었습니다!"
    else
      redirect_to prototype_login_path, alert: "로그인이 필요합니다."
    end
  end

  def admin_dashboard
    # 1. System-Wide Dashboard Stats (Overview)
    @total_users = User.count
    @premium_users = User.joins(:routine_club_members).where(routine_club_members: { status: :active }).distinct.count
    today = Date.current
    @daily_active_users = User.joins("LEFT JOIN personal_routines ON personal_routines.user_id = users.id")
                           .joins("LEFT JOIN personal_routine_completions ON personal_routine_completions.personal_routine_id = personal_routines.id")
                           .joins("LEFT JOIN rufa_activities ON rufa_activities.user_id = users.id")
                           .where("personal_routine_completions.completed_on = ? OR rufa_activities.created_at >= ?", today, today.beginning_of_day)
                           .distinct.count
    @system_pulse = (@daily_active_users.to_f / @total_users * 100).round(1) rescue 0

    # 2. User Management Data
    @users_query = User.order(created_at: :desc)

    if params[:user_search].present?
      @users_query = @users_query.where("nickname LIKE ? OR email LIKE ?", "%#{params[:user_search]}%", "%#{params[:user_search]}%")
    end

    @member_filter = params[:member_filter] || "all"
    case @member_filter
    when "club"
      @users_query = @users_query.joins(:routine_club_members).where(routine_club_members: { status: :active }).distinct
    when "general"
      club_user_ids = RoutineClubMember.where(status: :active).pluck(:user_id).uniq
      @users_query = @users_query.where.not(id: club_user_ids)
    end

    @users = @users_query.limit(50) # Limit for prototype performance

    # 3. Content Management Data
    @all_challenges = Challenge.includes(:host, :participants).order(created_at: :desc)
    @active_challenges = @all_challenges.online_challenges.limit(20)
    @active_gatherings = @all_challenges.offline_gatherings.limit(20)
    @pending_challenges = @all_challenges.where(status: :upcoming).limit(20) # Keeping for info, but no longer 'mandatory' approval flow

    # 4. Stream Data (for Logs tab)
    @stream_memberships = RoutineClubMember.joins(:user).includes(:user, :routine_club).order(created_at: :desc).limit(15)
    @stream_joins = Participant.joins(:user, :challenge).includes(:user, :challenge).order(created_at: :desc).limit(15)
    @stream_completions = PersonalRoutineCompletion.joins(personal_routine: :user).includes(personal_routine: :user).order(created_at: :desc).limit(15)
    @stream_activities = RufaActivity.joins(:user).includes(:user).order(created_at: :desc).limit(15)

    # 5. Financial Overview (Concept)
    @total_deposits = Challenge.where(cost_type: :deposit).sum(:amount)
    @total_fees = Challenge.where(cost_type: :fee).sum(:amount)
  end

  def club_management
    @official_club = RoutineClub.official.first || RoutineClub.first

    if @official_club
      # Real members of the official club
      @club_members = @official_club.members.confirmed.includes(:user).order(attendance_rate: :desc)
      @pending_memberships = @official_club.members.payment_status_pending.includes(:user)

      @member_stats = @club_members.map do |member|
        {
          member: member,
          weekly_rate: member.attendance_rate,
          monthly_rate: member.attendance_rate,
          growth_trend: nil
        }
      end
      # Announcements
      @announcements = @official_club.announcements.order(created_at: :desc)
    else
      @club_members = []
      @pending_memberships = []
      @member_stats = []
      @announcements = []
    end

    @club_admins = User.where(role: :club_admin).order(created_at: :desc)
  end

  def member_reports
    @target_user = User.find(params[:user_id])
    @reports = @target_user.routine_club_reports.order(start_date: :desc)
    @official_club = RoutineClub.official.first
  end

  def batch_reports
    @official_club = RoutineClub.official.first || RoutineClub.first
    @report_type = params[:type] || "weekly"

    # Calculate the target period (Previous Week: Mon-Sun, Previous Month: 1st-End)
    if @report_type == "weekly"
      # Monday of last week to Sunday of last week
      @target_start = (Date.current - 1.week).beginning_of_week
      @target_end = @target_start.end_of_week
    else
      # 1st of last month to Last day of last month
      @target_start = (Date.current - 1.month).beginning_of_month
      @target_end = @target_start.end_of_month
    end

    @reports = RoutineClubReport.where(
      report_type: @report_type,
      start_date: @target_start
    ).includes(:user).order("achievement_rate DESC")
  end

  def broadcast
    title = params[:title]
    content = params[:content]

    User.active.find_each do |user|
      user.notifications.create!(
        title: "📢 #{title}",
        content: content,
        notification_type: :system
      )
    end

    render json: { status: "success", message: "Broadcasting initiated for #{User.active.count} users." }
  end

  def update_user_role
    user = User.find(params[:user_id])
    new_role = params[:role]

    if user.update(role: new_role)
      render json: { status: "success", message: "#{user.nickname}님의 권한이 #{new_role}(으)로 변경되었습니다." }
    else
      render json: { status: "error", message: "권한 변경에 실패했습니다." }
    end
  end

  def update_user_status
    user = User.find(params[:user_id])
    new_status = params[:status]

    case new_status
    when "active"
      user.update(deleted_at: nil, suspended_at: nil)
      message = "#{user.nickname}님의 계정이 활성화되었습니다."
    when "suspended"
      user.update(deleted_at: nil, suspended_at: Time.current)
      message = "#{user.nickname}님의 계정이 정지되었습니다."
    when "withdrawn"
      user.update(deleted_at: Time.current, suspended_at: nil)
      message = "#{user.nickname}님이 탈퇴 처리되었습니다."
    else
      return render json: { status: "error", message: "잘못된 상태 값입니다." }
    end

    render json: { status: "success", message: message, current_status: new_status }
  end

  def approve_challenge
    challenge = Challenge.find(params[:challenge_id])
    if challenge.update(status: :active)
      render json: { status: "success", message: "'#{challenge.title}' 챌린지가 승인되었습니다." }
    else
      render json: { status: "error", message: "승인 처리에 실패했습니다." }
    end
  end

  def delete_content
    challenge = Challenge.find(params[:id])
    if challenge.destroy
      render json: { status: "success", message: "'#{challenge.title}'이(가) 삭제되었습니다." }
    else
      render json: { status: "error", message: "삭제에 실패했습니다." }
    end
  end

  def notify_host
    challenge = Challenge.find(params[:id])
    host = challenge.host
    content = params[:content]

    # Prototype notification logic
    if host.notifications.create(
      title: "관리자 메시지: '#{challenge.title}' 관련",
      content: content,
      notification_type: :notice,
      related_resource: challenge
    )
      render json: { status: "success", message: "#{host.nickname}님께 공지를 전송했습니다." }
    else
      render json: { status: "error", message: "공지 전송에 실패했습니다." }
    end
  end

  def update_content_basic
    challenge = Challenge.find(params[:id])
    if challenge.update(params.permit(:title, :category))
      render json: { status: "success", message: "콘텐츠 정보가 수정되었습니다." }
    else
      render json: { status: "error", message: "수정에 실패했습니다." }
    end
  end

  def purge_cache
    Rails.cache.clear
    render json: { status: "success", message: "시스템 캐시가 모두 초기화되었습니다." }
  end

  def update_profile
    if current_user
      # Support both nested (params[:user]) and flat parameters
      p = params[:user].presence || params

      update_params = {}
      update_params[:nickname] = p[:nickname] if p[:nickname].present?
      update_params[:bio] = p[:bio] if p[:bio].present?

      # Handle profile image upload correctly via ActiveStorage
      img = params[:profile_image] || p[:profile_image] || params[:avatar] || p[:avatar]
      if img.present?
        # 파일 검증
        validation_result = FileUploadValidator.validate_image(img)
        unless validation_result[:valid]
          redirect_to prototype_my_path, alert: validation_result[:error] and return
        end

        current_user.avatar.attach(img)
        # Clear legacy string column to let the profile_image method prefer avatar
        update_params[:profile_image] = nil
      end

      # Handle SNS links if provided
      sns = params[:sns_links] || p[:sns_links]
      if sns.present?
        links = {}
        sns.each do |link|
          next if link.blank?
          if link.include?("instagram.com")
            links["instagram"] = link
          elsif link.include?("threads.net")
            links["threads"] = link
          elsif link.include?("youtube.com")
            links["youtube"] = link
          elsif link.include?("twitter.com") || link.include?("x.com")
            links["twitter"] = link
          elsif link.include?("blog.naver.com") || link.include?("tistory.com")
            links["blog"] = link
          else
            links["other_#{links.size}"] = link
          end
        end
        update_params[:sns_links] = links
      end

      if current_user.update(update_params)
        redirect_to prototype_my_path, notice: "프로필이 성공적으로 업데이트되었습니다!"
      else
        redirect_to prototype_my_path, alert: "프로필 업데이트에 실패했습니다: #{current_user.errors.full_messages.join(', ')}"
      end
    else
      redirect_to prototype_login_path, alert: "로그인이 필요합니다."
    end
  end

  def update_club_lounge
    @official_club = RoutineClub.official.first || RoutineClub.first
    if @official_club
      if @official_club.update(lounge_params)
        redirect_to prototype_admin_clubs_path, notice: "라운지 설정이 저장되었습니다."
      else
        redirect_to prototype_admin_clubs_path, alert: "저장에 실패했습니다."
      end
    else
      redirect_to prototype_admin_clubs_path, alert: "공식 클럽을 찾을 수 없습니다."
    end
  end

  def reset_users
    keep_email = "jorden00@naver.com"
    keep_user = User.find_by(email: keep_email)

    if keep_user.nil?
      redirect_to prototype_admin_clubs_path, alert: "보존할 유저(#{keep_email})를 찾을 수 없습니다."
      return
    end

    ActiveRecord::Base.transaction do
      # 1. Delete all users except keep_user
      User.where.not(id: keep_user.id).destroy_all

      # 2. Cleanup remaining user's data
      RoutineClubMember.where(user_id: keep_user.id).destroy_all
      PersonalRoutine.where(user_id: keep_user.id).destroy_all
      PersonalRoutineCompletion.where(user_id: keep_user.id).delete_all
    end

    redirect_to prototype_admin_clubs_path, notice: "유저 정보가 초기화되었습니다. (#{keep_email} 제외)"
  rescue => e
    redirect_to prototype_admin_clubs_path, alert: "오류 발생: #{e.message}"
  end

  private

  def set_shared_data
    @official_club = RoutineClub.ensure_official_club
    @new_badges = current_user ? current_user.user_badges.where(is_viewed: false).includes(:badge) : []
  end

  def lounge_params
    params.require(:routine_club).permit(
    :title, :description, :bank_name, :account_number, :account_holder,
    :weekly_reward_info, :monthly_reward_info, :season_reward_info,
    :relax_pass_limit, :save_pass_limit, :golden_fire_bonus, :auto_kick_threshold, :completion_attendance_rate,
    :zoom_link, :live_room_title, :live_room_button_text, :live_room_active,
    :special_lecture_link, :lecture_room_title, :lecture_room_description, :lecture_room_active
  )
  end
end
