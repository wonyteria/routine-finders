class PrototypeController < ApplicationController
  require "ostruct"
  include PrototypeErrorHandler

  layout "prototype"
  before_action :set_shared_data
  before_action :require_login, only: [ :my, :routine_builder, :challenge_builder, :gathering_builder, :club_join, :record, :notifications, :clear_notifications, :pwa, :admin_dashboard, :club_management, :member_reports, :batch_reports, :confirm_club_payment, :reject_club_payment, :create_club_announcement, :update_club_lounge ]
  before_action :require_admin, only: [ :admin_dashboard, :club_management, :member_reports, :batch_reports, :confirm_club_payment, :reject_club_payment, :create_club_announcement, :update_club_lounge ]
  before_action :require_super_admin, only: [ :broadcast, :update_user_role, :update_user_status, :approve_challenge, :purge_cache, :reset_users, :delete_content, :notify_host, :update_content_basic ]
  before_action :require_can_create_challenge, only: [ :challenge_builder ]
  before_action :require_can_create_gathering, only: [ :gathering_builder ]

  def login
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
      # Force removal of greeting flash so they NEVER overlap
      flash.delete(:show_daily_greeting)
      flash.now[:show_daily_greeting] = nil
    end

    # 2. Routine & Task Progress (Real data)
    # Use numeric string (0-6) to match the stored data in personal_routines.days
    current_wday = Date.current.wday.to_s
    @todays_routines = current_user ? current_user.personal_routines.where(deleted_at: nil).select { |r| (r.days || []).map(&:to_s).include?(current_wday) } : []

    # Fix: Filter out finished challenges from 'Today's Tasks'
    @joined_participations = current_user ? current_user.participations.active.joins(:challenge).where("challenges.start_date <= ? AND challenges.end_date >= ?", Date.current, Date.current) : Participant.none

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
      avg = RoutineClubMember.joins(:user).where(users: { deleted_at: nil }, status: :active, payment_status: :confirmed).average(:attendance_rate)
      avg&.round(1) || 0
    end rescue 72

    @total_active_metes = User.joins(:rufa_activities)
                              .where("rufa_activities.created_at >= ?", 30.minutes.ago)
                              .distinct.count
    @total_active_metes = [ @total_active_metes, @orbit_users.count ].max

    # 5. Specialized Content (Ranking & Goals) - Use minimal calculation
    @rufa_rankings = Rails.cache.fetch("home_rankings_stable_v2", expires_in: 1.hour) do
      User.active
          .joins(:routine_club_members)
          .where(routine_club_members: { status: [ :active, :warned ], payment_status: :confirmed })
          .where("routine_club_members.membership_start_date <= ? AND routine_club_members.membership_end_date >= ?", Date.current, Date.current)
          .limit(20)
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

        # [Push Notification Onboarding]
        # Show if club member + not dismissed + not subscribed
        if @is_club_member
          subscribed = current_user.web_push_subscriptions.exists?
          # Show if not subscribed yet.
          @show_push_onboarding = !subscribed
        end
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
    # Challenges: online mode only
    challenges_query = Challenge.includes(:host, :participants)
                                .where("end_date >= ?", Date.current)
                                .where(mode: :online)

    # Gatherings: offline mode only
    gatherings_query = Challenge.includes(:host, :participants)
                                .where("end_date >= ?", Date.current)
                                .where(mode: :offline)

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
    club_member_user_ids = User.joins(:routine_club_members)
                               .where(routine_club_members: { status: [ :active, :warned ], payment_status: :confirmed })
                               .where("routine_club_members.membership_start_date <= ? AND routine_club_members.membership_end_date >= ?", Date.current, Date.current)
                               .pluck(:id)
    admin_user_ids = User.admin.pluck(:id)
    all_club_ids = (club_member_user_ids + admin_user_ids).uniq

    relevant_users = User.where(deleted_at: nil)
                         .where.not(role: :super_admin)
                         .where(id: (active_activity_user_ids + all_club_ids).uniq)

    @period = params[:period] || "monthly" # monthly or total

    @monthly_rankings = relevant_users.map { |u|
      score = if @period == "total"
                u.total_platform_score
      else
                u.rufa_club_score # This is monthly score logic
      end

      {
        user: u,
        score: score,
        is_club: all_club_ids.include?(u.id)
      }
    }.sort_by { |r| -r[:score] }

    if params[:rank_type] == "club"
      @monthly_rankings = @monthly_rankings.select { |r| r[:is_club] }
    end

    @monthly_rankings = @monthly_rankings.take(100) # Limit to top 100

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
  end

  def my
    if current_user
      Rails.logger.info "[Debug] User #{current_user.id} loaded My page. " \
                        "Nickname: '#{current_user.nickname}', Bio: '#{current_user.bio}', " \
                        "Weekly Goal: '#{current_user.weekly_goal}', Monthly Goal: '#{current_user.monthly_goal}'"
    end
    @total_activities = current_user&.total_routine_completions || 0
    @current_streak = current_user&.personal_routines&.maximum(:current_streak) || 0
    @current_month_points = current_user&.current_month_points || 0
    @total_platform_score = current_user&.total_platform_score || 0
    @achievements = current_user&.user_badges&.includes(:badge)&.limit(10) || []

    if current_user
      # Calculate progress for next milestones
      @milestones = []

      # 1. Verification Count (Routine)
      current_verifications = current_user.personal_routines.where(deleted_at: nil).joins(:completions).count
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
      max_streak = current_user.personal_routines.where(deleted_at: nil).maximum(:current_streak) || 0
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

    # 4. Growth Analytics (Fixed Period Logic)

    # [Weekly]: 월~일 (7일 고정)
    @weekly_labels = [ "월", "화", "수", "목", "금", "토", "일" ]
    @weekly_data = Array.new(7, 0)
    current_week_start = Date.current.beginning_of_week
    # 오늘이 월요일이면 0, 일요일이면 6
    @daily_index = (Date.current - current_week_start).to_i

    (0..@daily_index).each do |i|
      date = current_week_start + i.days
      @weekly_data[i] = current_user.daily_achievement_rate(date).round
    end

    # [Monthly]: 1일~말일 기준 주차별 (최대 6주, 보통 4-5주) -> UI상 5개 고정 권장이나 로직은 유연하게
    # 이번 달의 1주차, 2주차... 로직
    # 해당 월의 첫 날이 속한 주를 1주차로 계산
    current_month_start = Date.current.beginning_of_month
    current_month_end = Date.current.end_of_month

    # 이번 달의 전체 주 수 계산 (보통 4~6주)
    # 방식: 매주 월요일 기준으로 주차를 나눔
    # 1주차: 1일 ~ 첫번째 일요일
    # 2주차: 그 다음 월요일 ~ 일요일 ...
    @monthly_labels = []
    @monthly_data = []

    temp_date = current_month_start
    week_num = 1
    @weekly_index = 0 # 이번 주가 몇 번째 인덱스인지

    while temp_date <= current_month_end
      week_end = [ temp_date.end_of_week, current_month_end ].min
      label = "#{Date.current.month}월 #{week_num}주"
      @monthly_labels << label

      # 미래 주차는 0, 지나간/현재 주차는 계산
      if temp_date > Date.current
        @monthly_data << 0
      else
        @monthly_data << current_user.period_routine_rate(temp_date, week_end).round
      end

      # 현재 날짜가 이 주간에 포함되면 인덱스 저장
      if (temp_date..week_end).cover?(Date.current)
        @weekly_index = week_num - 1
      end

      temp_date = week_end + 1.day
      week_num += 1
    end

    # [Yearly]: 1월~12월 (12개월 고정)
    @yearly_labels = (1..12).map { |m| "#{m}월" }
    @yearly_data = Array.new(12, 0)
    @monthly_index = Date.current.month - 1 # 현재 월 인덱스 (0-based)

    (1..Date.current.month).each do |m|
      month_start = Date.new(Date.current.year, m, 1)
      month_end = month_start.end_of_month

      # 미래 날짜 제외 로직 (이번 달은 오늘까지만, 지난 달은 전체)
      calc_end = [ month_end, Date.current ].min

      @yearly_data[m-1] = current_user.period_routine_rate(month_start, calc_end).round
    end

    # Summaries (Calculated as Total Completed / Total Required for the period)
    # Weekly Summary
    w_start = Date.current.beginning_of_week
    w_end = Date.current
    @weekly_completion = current_user.period_routine_rate(w_start, w_end).round

    days_passed = [ (Date.current - w_start).to_i, 0 ].max
    today_val = @weekly_data[days_passed]
    yesterday_val = days_passed > 0 ? @weekly_data[days_passed - 1] : 0
    @weekly_growth = today_val - yesterday_val

    # Monthly Summary
    m_start = Date.current.beginning_of_month
    m_end = Date.current
    @monthly_completion = current_user.period_routine_rate(m_start, m_end).round
    @monthly_growth = @monthly_data.size >= 2 ? (@monthly_data[-1] - @monthly_data[-2]) : 0

    # Yearly Summary
    y_start = Date.current.beginning_of_year
    y_end = Date.current
    @yearly_completion = current_user.period_routine_rate(y_start, y_end).round
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
    @active_routine_count = current_user ? current_user.personal_routines.where(deleted_at: nil).count : 0
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
    @routines = current_user ? current_user.personal_routines.where(deleted_at: nil).order(created_at: :desc) : []
    render layout: "prototype"
  end

  def live
    @current_club = RoutineClub.official.first

    # Collective Data for RUFA Club
    @confirmed_members = @current_club&.members&.joins(:user)&.where(users: { deleted_at: nil }, payment_status: :confirmed) || []
    @club_total_members_count = @confirmed_members.count

    # 1. Today's Average Achievement for Club Members
    @club_today_avg_achievement = Rails.cache.fetch("club_today_avg_#{Date.current}", expires_in: 30.minutes) do
      member_rates = @confirmed_members.map { |m| m.user.daily_achievement_rate(Date.current) }
      (member_rates.sum.to_f / [ member_rates.size, 1 ].max).round(1)
    end

    # 2. Season Cumulative Average Achievement for Club Members
    @club_season_avg_achievement = Rails.cache.fetch("club_season_avg_#{Date.current}", expires_in: 30.minutes) do
      avg = @confirmed_members.average(:attendance_rate)
      avg&.round(1) || 0
    end

    @club_weekly_completions = @club_season_avg_achievement
    @club_temperature = @club_today_avg_achievement

    @club_announcements = @current_club&.announcements&.order(created_at: :desc)&.limit(2) || []
    @is_club_member = current_user&.is_rufa_club_member?
    unless @is_club_member
      flash[:is_rufa_pending] = true if current_user&.is_rufa_pending?
      redirect_to guide_routine_clubs_path(source: "prototype"), alert: "라운지 입장은\n루파 클럽 멤버 전용 혜택입니다." and return
    end
  end

  def user_profile
    @target_user = User.find(params[:id])
    @achievements = @target_user.user_badges.includes(:badge).order(created_at: :desc).limit(6)
    @routines = @target_user.personal_routines.where(deleted_at: nil).order(created_at: :desc)
    @total_badges_count = @target_user.user_badges.count
    @is_club_member = @target_user.routine_club_members.active.exists?
    @my_membership = @target_user.routine_club_members.active.first

    # Weekly Stats for Card (Matches Achievement Report logic)
    start_of_week = Date.current.beginning_of_week
    @weekly_completion = @target_user.period_routine_rate(start_of_week, Date.current).to_i

    if request.headers["Turbo-Frame"]
      render layout: false
    else
      render layout: "prototype"
    end
  rescue ActiveRecord::RecordNotFound
    render plain: "User not found", status: 404
  end

  def lecture_intro
    @hide_nav = true
    @is_club_member = current_user&.is_rufa_club_member?
    unless @is_club_member
      flash[:is_rufa_pending] = true if current_user&.is_rufa_pending?
      redirect_to guide_routine_clubs_path(source: "prototype"), alert: "강의 시청은\n루파 클럽 멤버 전용 혜택입니다." and return
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
    # Prioritize recruiting clubs, then future clubs, then falls back to latest
    @routine_club = RoutineClub.official.recruiting_clubs.first ||
                    RoutineClub.official.where("start_date > ?", Date.current).order(start_date: :asc).first ||
                    RoutineClub.official.order(start_date: :desc).first ||
                    RoutineClub.order(created_at: :desc).first

    @is_member = current_user&.routine_club_members&.exists?(routine_club: @routine_club, status: :active)
  end

  def mark_badges_viewed
    current_user&.user_badges&.where(is_viewed: false)&.update_all(is_viewed: true)
    head :ok
  end

  def update_goals
    if current_user
      # Support both nested (params[:user]) and flat parameters
      p = params[:user].presence || params

      update_params = {}
      # Use key? check to support both string and symbol keys and allow clearing content
      update_params[:weekly_goal] = p[:weekly_goal] if p.key?(:weekly_goal) || p.key?("weekly_goal")
      update_params[:monthly_goal] = p[:monthly_goal] if p.key?(:monthly_goal) || p.key?("monthly_goal")
      update_params[:yearly_goal] = p[:yearly_goal] if p.key?(:yearly_goal) || p.key?("yearly_goal")

      # Timestamps: Only update if the goal parameter was actually sent
      update_params[:weekly_goal_updated_at] = Time.current if update_params.key?(:weekly_goal)
      update_params[:monthly_goal_updated_at] = Time.current if update_params.key?(:monthly_goal)
      update_params[:yearly_goal_updated_at] = Time.current if update_params.key?(:yearly_goal)

      if current_user.update(update_params)
        current_user.reload
        Rails.logger.info "Goals updated for User #{current_user.id}: #{update_params.keys.join(', ')}"
        redirect_to prototype_my_path, notice: "목표가 성공적으로 저장되었습니다!"
      else
        Rails.logger.error "Failed to update goals for User #{current_user.id}: #{current_user.errors.full_messages.join(', ')}"
        redirect_to prototype_my_path, alert: "목표 저장에 실패했습니다: #{current_user.errors.full_messages.join(', ')}"
      end
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

    # 5. Push Notification Settings
    @push_configs = [
      PushNotificationConfig.morning_affirmation,
      PushNotificationConfig.evening_reminder,
      PushNotificationConfig.night_check
    ] rescue []
  end

  def update_push_config
    config = PushNotificationConfig.find_or_initialize_by(config_type: params[:config_type])
    if config.update(push_notification_config_params)
      redirect_to prototype_admin_dashboard_path(tab: "push"), notice: "푸시 설정이 저장되었습니다."
    else
      redirect_to prototype_admin_dashboard_path(tab: "push"), alert: "실패: #{config.errors.full_messages.join(', ')}"
    end
  end

  def club_management
    @official_club = RoutineClub.ensure_official_club

    if @official_club
      # Ensure current admin has membership before loading the page (Fix for admins not being members)
      current_user.ensure_rufa_club_membership_for_admin if current_user&.admin?

      # Real members of the official club (Exclude deleted users)
      @club_members = @official_club.members.confirmed.joins(:user).where(users: { deleted_at: nil }).includes(user: { personal_routines: :completions })

      # [Sorting Logic]
      @member_sort = params[:member_sort] || "weekly_high"

      # Fix: Fetch pending memberships from ALL active clubs to ensure no application is missed (Exclude deleted users)
      @pending_memberships = RoutineClubMember.where(payment_status: :pending).joins(:user).where(users: { deleted_at: nil }).includes(:user, :routine_club).order(created_at: :desc)

      @member_stats = @club_members.map do |member|
        {
          member: member,
          weekly_rate: member.weekly_routine_rate, # 메인 노출: 루틴 개수 기준 수행률
          monthly_rate: member.monthly_routine_rate,
          weekly_attendance: member.weekly_attendance_rate, # 보조: 출석 기준 달성률
          monthly_attendance: member.monthly_attendance_rate,
          created_at: member.created_at,
          growth_trend: nil
        }
      end

      case @member_sort
      when "weekly_low"
        @member_stats.sort_by! { |s| s[:weekly_rate] }
      when "monthly_high"
        @member_stats.sort_by! { |s| -s[:monthly_rate] }
      when "monthly_low"
        @member_stats.sort_by! { |s| s[:monthly_rate] }
      when "join_newest"
        @member_stats.sort_by! { |s| -s[:created_at].to_i }
      when "join_oldest"
        @member_stats.sort_by! { |s| s[:created_at].to_i }
      else # weekly_high (default)
        @member_stats.sort_by! { |s| -s[:weekly_rate] }
      end

      @club_members = @member_stats.map { |s| s[:member] }
      # Announcements
      @announcements = @official_club.announcements.order(created_at: :desc)
    else
      @club_members = []
      @pending_memberships = []
      @member_stats = []
      @announcements = []
    end

    # Include both club_admin and super_admin in staff list (Exclude deleted users)
    @club_admins = User.where(role: [ :club_admin, :super_admin ]).where(deleted_at: nil).order(created_at: :desc)
  end

  def member_reports
    @target_user = User.find(params[:user_id])
    @reports = @target_user.routine_club_reports.order(start_date: :desc)
    @official_club = RoutineClub.official.first

    # [Added] Weekly Live Analysis for transparency
    week_start = Date.current.beginning_of_week
    week_end = Date.current

    # Pre-fetch personal routines to minimize queries, using the new logic (exclude deleted)
    personal_routines = @target_user.personal_routines

    @weekly_analysis = (week_start..week_end).map do |date|
      # Filter active routines for this date: created on/before date AND includes the day of week
      todays_active_routines = personal_routines.select do |r|
        created_condition = r.created_at.to_date <= date
        day_condition = (r.days || []).include?(date.wday.to_s)
        created_condition && day_condition
      end

      total_count = todays_active_routines.size

      # Find completed routine IDs for this date
      completed_routine_ids = PersonalRoutineCompletion
                                .where(personal_routine_id: todays_active_routines.map(&:id))
                                .where(completed_on: date)
                                .pluck(:personal_routine_id)

      completed_count = completed_routine_ids.size
      achievement_rate = total_count > 0 ? (completed_count.to_f / total_count * 100).round(1) : 0

      # Identify missed routines for detailed feedback
      missed_routines = todays_active_routines.reject { |r| completed_routine_ids.include?(r.id) }

      {
        date: date,
        day_name: %w[일 월 화 수 목 금 토][date.wday],
        total: total_count,
        completed: completed_count,
        rate: achievement_rate,
        missed: missed_routines.map(&:title)
      }
    end
  end

  def analyze_member_performance
    @target_user = User.find(params[:user_id])
    @analysis_type = params[:type] || "weekly"

    if @analysis_type == "weekly"
      start_date = Date.current.beginning_of_week
      end_date = Date.current
      @analysis_title = "이번 주 실시간 분석"
    else
      start_date = Date.current.beginning_of_month
      end_date = Date.current
      @analysis_title = "이번 달 실시간 분석"
    end

    # [Fix] 삭제된 루틴은 통계에서 영구 제외
    personal_routines = @target_user.personal_routines.where(deleted_at: nil)

    # [Added] 해당 기간 내 출석 데이터(패스 사용 여부 확인용)
    attendance_map = @target_user.routine_club_members.confirmed.first&.attendances
                      &.where(attendance_date: start_date..end_date)
                      &.index_by(&:attendance_date) || {}

    # 1. 일별 데이터 계산
    daily_data = (start_date..end_date).map do |date|
      todays_active_routines = personal_routines.select do |r|
        created_condition = r.created_at.to_date <= date

        # [Safety] days가 String(JSON)으로 반환될 경우 배열로 파싱
        days_list = r.days
        if days_list.is_a?(String)
          begin
            days_list = JSON.parse(days_list)
          rescue JSON::ParserError
            days_list = []
          end
        end

        day_condition = (days_list || []).include?(date.wday.to_s)
        created_condition && day_condition
      end

      total_count = todays_active_routines.size

      completed_routine_ids = PersonalRoutineCompletion
                                .where(personal_routine_id: todays_active_routines.map(&:id))
                                .where(completed_on: date)
                                .pluck(:personal_routine_id)

      # [Logic] 패스 사용 여부 확인
      is_excused = attendance_map[date]&.status == "excused"

      completed_count = completed_routine_ids.size

      # 패스 사용 시 100%로 간주, 아닐 경우 실제 완료율 계산
      achievement_rate = if is_excused
                           100.0
      else
                           total_count > 0 ? (completed_count.to_f / total_count * 100).round(1) : 0
      end

      missed_routines = todays_active_routines.reject { |r| completed_routine_ids.include?(r.id) }

      {
        date: date,
        day_name: %w[일 월 화 수 목 금 토][date.wday],
        total: total_count,
        completed: is_excused ? total_count : completed_count, # 패스 사용 시 전체 완료로 표시
        rate: achievement_rate,
        is_excused: is_excused,
        missed: is_excused ? [] : missed_routines.map(&:title)
      }
    end

    # 2. 월간일 경우 주차별 그룹화 (Weekly Aggregation)
    if @analysis_type == "monthly"
      # 날짜 오름차순으로 정렬 후 그룹화
      sorted_days = daily_data.sort_by { |d| d[:date] }

      # 주차별 그룹화 (ActiveSupport의 beginning_of_week 기준)
      # 그 달의 첫째 주, 둘째 주... 계산
      grouped_weeks = sorted_days.group_by do |d|
        # 월의 몇 번째 주인지 계산 (간단한 버전: 날짜 / 7 + 1 아님. 달력 기준)
        # strftime("%W")는 연중 주차. 이걸로 그룹화하면 됨.
        d[:date].strftime("%W").to_i
      end

      @daily_analysis = grouped_weeks.map do |week_num, days|
        total_required = days.sum { |d| d[:total] }
        total_completed = days.sum { |d| d[:completed] }
        avg_rate = total_required > 0 ? (total_completed.to_f / total_required * 100).round(1) : 0

        # 해당 주차의 기간 (시작일 ~ 종료일)
        week_start = days.first[:date]
        week_end = days.last[:date]

        # 월의 몇 주차인지 재계산 (표시용)
        # 해당 월의 1일이 속한 연중 주차와 비교
        first_week_of_month = week_start.beginning_of_month.strftime("%W").to_i
        current_week_of_month = week_num - first_week_of_month + 1

        # 가장 많이 놓친 루틴 Top 3
        missed_counts = days.flat_map { |d| d[:missed] }.tally
        top_missed = missed_counts.sort_by { |_, v| -v }.take(2).map(&:first)

        {
          is_weekly_summary: true,
          week_label: "#{week_start.month}월 #{current_week_of_month}주차",
          date_range: "#{week_start.strftime('%m.%d')} ~ #{week_end.strftime('%m.%d')}",
          total: total_required,
          completed: total_completed,
          rate: avg_rate,
          missed: top_missed, # 주요 미달성 루틴만
          missed_more_count: [ missed_counts.size - 2, 0 ].max
        }
      end.reverse # 최신 주차가 위로 오게
    else
      # 주간일 경우 일별 데이터 그대로 사용 (역순 정렬)
      @daily_analysis = daily_data.reverse
    end

    render partial: "prototype/member_analysis_modal_content", layout: false
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

    # 모든 확정 멤버(payment_status: :confirmed)를 대상으로 하되, '루파' 닉네임 유저만 제외
    confirmed_members = @official_club.members.confirmed.joins(:user).where(users: { deleted_at: nil }).where.not(users: { nickname: "루파" }).includes(:user)

    # 1. 존재하는 리포트들 가져오기
    existing_reports = RoutineClubReport.where(
      report_type: @report_type,
      start_date: @target_start,
      routine_club: @official_club
    ).index_by(&:user_id)

    @reports = []

    confirmed_members.each do |member|
      report = existing_reports[member.user_id]

      # 리포트가 없으면 즉석 생성
      unless report
        report = RoutineClubReportService.new(
          user: member.user,
          routine_club: @official_club,
          report_type: @report_type,
          start_date: @target_start,
          end_date: @target_end
        ).generate_or_find
      end

      next unless report

      # [Logic] 경고 적합성 판단 및 부가 정보 추가
      # 주간 점검 로직과 동일: 70% 미만일 때, 기준일(월요일) 이전에 가입했는지 체크
      is_eligible = member.joined_at.to_date <= @target_start
      has_low_rate = report.achievement_rate < 70.0

      # 리포트 오브젝트에 동적 속성 주입 (View에서 사용)
      # Ruby의 singleton_class를 이용하거나 Hash/OpenStruct로 래핑
      decorated_report = Struct.new(*report.attributes.keys.map(&:to_sym), :is_eligible, :has_low_rate, :user).new(*report.attributes.values, is_eligible, has_low_rate, report.user)

      @reports << decorated_report
    end

    # 달성률 순 정렬
    @reports = @reports.sort_by { |r| -(r.achievement_rate || 0) }
  end

  def create_club_announcement
    @official_club = RoutineClub.official.first || RoutineClub.first

    if @official_club
      announcement = @official_club.announcements.build(
        title: params[:title],
        content: params[:content]
      )

      if announcement.save
        RoutineClubNotificationService.notify_announcement(@official_club, announcement)
        redirect_to prototype_admin_clubs_path(tab: "announcements"), notice: "공지사항이 등록되고 모든 멤버에게 알림이 발송되었습니다."
      else
        redirect_to prototype_admin_clubs_path(tab: "announcements"), alert: "공지 등록 실패: #{announcement.errors.full_messages.join(', ')}"
      end
    else
      redirect_to prototype_admin_clubs_path, alert: "운영 중인 공식 클럽이 없습니다."
    end
  end

  def update_club_announcement
    @announcement = Announcement.find(params[:id])
    if @announcement.update(title: params[:title], content: params[:content])
      redirect_to prototype_admin_clubs_path(tab: "announcements"), notice: "공지사항이 수정되었습니다."
    else
      redirect_to prototype_admin_clubs_path(tab: "announcements"), alert: "공지 수정 실패: #{@announcement.errors.full_messages.join(', ')}"
    end
  end

  def confirm_club_payment
    member = RoutineClubMember.find(params[:member_id])

    begin
      member.confirm_payment!
      redirect_to prototype_admin_clubs_path(tab: "members"), notice: "#{member.user.nickname}님의 입금이 승인되었습니다."
    rescue => e
      redirect_to prototype_admin_clubs_path(tab: "members"), alert: "승인 처리에 실패했습니다: #{e.message}"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to prototype_admin_clubs_path, alert: "멤버를 찾을 수 없습니다."
  end

  def reject_club_payment
    member = RoutineClubMember.find(params[:member_id])
    reason = params[:reason] || "입금 확인 불가"

    begin
      member.reject_payment!(reason)
      redirect_to prototype_admin_clubs_path(tab: "members"), notice: "#{member.user.nickname}님의 입금이 거부되었습니다."
    rescue => e
      redirect_to prototype_admin_clubs_path(tab: "members"), alert: "거부 처리에 실패했습니다: #{e.message}"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to prototype_admin_clubs_path, alert: "멤버를 찾을 수 없습니다."
  end

  def admin_weekly_check
    @official_club = RoutineClub.official.first
    unless @official_club
      redirect_to prototype_admin_clubs_path, alert: "공식 클럽을 찾을 수 없습니다." and return
    end

    @evaluation_date = Date.current

    # 1. 지난주 결과 (확정 점검 대상)
    @last_week_start = @evaluation_date.last_week.beginning_of_week
    @last_week_end = @evaluation_date.last_week.end_of_week

    # 2. 이번 주 현황 (실시간 모니터링)
    @this_week_start = @evaluation_date.beginning_of_week
    @this_week_end = @evaluation_date.end_of_week

    # 공통 대상: 결제 완료된 정식 멤버이며, 운영진이 아닌 경우
    base_members = @official_club.members
                                .where(status: [ :active, :warned ])
                                .where(payment_status: :confirmed)
                                .where(is_moderator: false)
                                .includes(:attendances, user: :personal_routines)

    # 탭 A: 지난주 결과 기반 (오늘 경고 대상자들)
    @confirmed_risks = []
    base_members.find_each do |member|
      if member.check_weekly_performance!(@evaluation_date, dry_run: true)
        @confirmed_risks << {
          member: member,
          stats: member.performance_stats(@last_week_start, @last_week_end)
        }
      end
    end

    # 탭 B: 이번 주 실시간 현황 (현재 달성률 70% 미만인 유저들)
    @live_risks = []
    base_members.find_each do |member|
      # 가입일이 이번 주 월요일보다 늦으면 이번 주 평가에서는 제외될 예정이므로 모니터링에서도 일단 제외하거나 표시만 함
      next if member.joined_at && member.joined_at.to_date > @this_week_start

      stats = member.performance_stats(@this_week_start, [ @evaluation_date, @this_week_end ].min)
      # 현재까지 해야 할 루틴이 있는 경우에만 체크
      if stats[:total_required] > 0 && stats[:rate] < 70.0
        @live_risks << {
          member: member,
          stats: stats,
          needed: member.routines_needed_for_70_percent(@this_week_start, @this_week_end)
        }
      end
    end

    # 달성률 낮은 순으로 정렬
    @live_risks = @live_risks.sort_by { |r| r[:stats][:rate] }

    # 3. 이번 달 누적 경고 현황 (운영진 제외)
    all_members = @official_club.members.where(is_moderator: false).includes(:user, :penalties)
    @warned_members_this_month = all_members.select { |m| m.current_month_penalty_count > 0 }
           .sort_by { |m| -m.current_month_penalty_count }
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
    unless current_user
      redirect_to prototype_login_path, alert: "로그인이 필요합니다.", status: :see_other
      return
    end

    # 1. Strong Parameters - 정석적인 방법으로 파라미터 추출
    # View에서 name="user[nickname]" 형태로 보내므로 user 키가 반드시 존재해야 함을 가정하되,
    # 예외 상황(직접 요청 등)을 대비해 안전하게 처리
    begin
      user_params = params.require(:user).permit(:nickname, :bio, :profile_image, :avatar, sns_links: [])
    rescue ActionController::ParameterMissing
      # user 키가 없는 경우 (예: 잘못된 요청)
      user_params = ActionController::Parameters.new
    end

    update_params = {}

    # 2. Basic Info - 키가 존재하면(빈 문자열 포함) 업데이트 파라미터에 포함
    # permit을 통과한 파라미터 객체는 key? 메서드를 지원함
    update_params[:nickname] = user_params[:nickname] if user_params.key?(:nickname)
    update_params[:bio] = user_params[:bio] if user_params.key?(:bio)

    # 3. Image Handling
    img = user_params[:profile_image] || user_params[:avatar]
    if img.present? && img.respond_to?(:content_type)
      validation_result = FileUploadValidator.validate_image(img)
      unless validation_result[:valid]
        redirect_to prototype_my_path, alert: validation_result[:error], status: :see_other
        return
      end

      current_user.avatar.attach(img)
      update_params[:profile_image] = nil # Clear legacy field
    end

    # 4. SNS Links Handling
    if user_params[:sns_links].is_a?(Array)
      links = {}
      user_params[:sns_links].each do |link|
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

    # 5. Execute Update
    Rails.logger.info "[Profile Update] User #{current_user.id} payload: #{update_params.inspect}"

    if current_user.update(update_params)
      current_user.reload # Ensure fresh data for the view after redirect
      redirect_to prototype_my_path, notice: "프로필이 성공적으로 업데이트되었습니다!", status: :see_other
    else
      error_msg = current_user.errors.full_messages.join(", ")
      Rails.logger.error "[Profile Update Failed] User #{current_user.id}: #{error_msg}"
      redirect_to prototype_my_path, alert: "프로필 업데이트에 실패했습니다: #{error_msg}", status: :see_other
    end
  end

  def update_club_lounge
    @official_club = RoutineClub.official.first || RoutineClub.first
    if @official_club
      if @official_club.update(lounge_params)
        Rails.logger.info "Club settings updated for RoutineClub #{@official_club.id}"

        # Determine strict tab redirection based on what was updated
        target_tab = params.dig(:routine_club, :live_room_title) ? "lounge" : "settings"

        redirect_to prototype_admin_clubs_path(tab: target_tab), notice: "설정이 성공적으로 저장되었습니다."
      else
        error_msg = @official_club.errors.full_messages.join(", ")
        Rails.logger.error "Club update failed for RoutineClub #{@official_club.id}: #{error_msg}"
        redirect_to prototype_admin_clubs_path(tab: "settings"), alert: "저장에 실패했습니다: #{error_msg}"
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

  def push_notification_config_params
    params.require(:push_notification_config).permit(:title, :content, :schedule_time, :enabled, :link_url)
  end
end
