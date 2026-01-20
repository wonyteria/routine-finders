class PrototypeController < ApplicationController
  layout "prototype"
  before_action :set_shared_data
  before_action :require_login, only: [ :my, :routine_builder, :challenge_builder, :gathering_builder, :club_join, :record, :notifications, :clear_notifications, :pwa ]

  def login
    @hide_nav = true
  end

  def home
    # 1. Total Daily Tasks Calculation (Routines + Challenges + Gatherings)
    @todays_routines = current_user ? current_user.personal_routines.select { |r| (r.days || []).include?(Date.current.wday.to_s) } : []
    # Combined Active Participations (Challenges & Gatherings)
    @joined_participations = current_user ? current_user.participations.active.joins(:challenge) : Participant.none
    @todays_gatherings = @joined_participations.where(challenges: { start_date: Date.current })

    # Counts
    routine_total = @todays_routines.count
    participation_total = @joined_participations.count
    @total_task_count = routine_total + participation_total

    # Completed Counts
    routine_done = @todays_routines.select(&:completed_today?).count
    # Simplified: assume verification_logs for today exists for completed items
    participation_done = current_user ? VerificationLog.where(participant: @joined_participations, created_at: Date.current.all_day).pluck(:participant_id).uniq.count : 0

    @completed_count = routine_done + participation_done
    @progress = @total_task_count.positive? ? (@completed_count.to_f / @total_task_count * 100).to_i : 0

    # 2. Check for active club membership
    @membership = current_user&.routine_club_members&.active&.first
    @is_club_member = @membership.present?

    # 3. Live Feed Data (Active users only)
    @recent_activities = RufaActivity.joins(:user).where(users: { deleted_at: nil }).order(created_at: :desc).limit(10)
    @recent_reflections = @recent_activities.where(activity_type: [ "routine_record", "reflection" ])

    # Orbiting Users (Recent successes to show on home visualization)
    @orbit_users = User.joins(:rufa_activities)
                       .where(rufa_activities: { activity_type: "routine_record", created_at: Date.current.all_day })
                       .where.not(id: current_user&.id)
                       .distinct
                       .limit(100)

    # 4. Content for Dashboard
    if current_user
      @hosted_challenges = Challenge.where(host: current_user).order(created_at: :desc)
      @joined_challenges = current_user.challenges.active.where.not(id: @hosted_challenges.pluck(:id))
    else
      @hosted_challenges = []
      @joined_challenges = []
    end
  end

  def explore
    @featured_club = RoutineClub.active_clubs.order(created_at: :desc).first
    @tab_type = params[:type] || "all"
    @sort_type = params[:sort] || "recent"

    # 1. Closing Soon (Recruitment ends within 3 days)
    @closing_soon = Challenge.where("recruitment_end_date >= ? AND recruitment_end_date <= ?", Date.current, Date.current + 3.days)
                            .order(:recruitment_end_date).limit(5)

    # 2. Base Queries
    # 2. Base Queries (In a real app, we'd use a categorization flag)
    # For now, let's keep the mode separation but acknowledge they can overlap in UI
    challenges_query = Challenge.where("end_date >= ?", Date.current)
    gatherings_query = Challenge.where("end_date >= ?", Date.current).where.not(meeting_type: nil) # Heuristic for gatherings

    # 3. Apply Sorting
    order_clause = case @sort_type
    when "popular"
                     { current_participants: :desc }
    when "amount"
                     { amount: :desc }
    else
                     { created_at: :desc }
    end

    # Fill with dummy data if not enough real ones
    dummies = Challenge.generate_dummy_challenges

    @active_challenges = (challenges_query.order(order_clause).limit(6).to_a + dummies.select { |d| d.mode == "online" }).uniq { |c| c.title }.first(6)
    @gatherings = (gatherings_query.order(order_clause).limit(6).to_a + dummies.select { |d| d.mode == "offline" }).uniq { |c| c.title }.first(6)
  end

  def synergy
    # Hall of Fame: Monthly rankings for active Rufa Club members
    active_members = User.joins(:routine_club_members)
                        .where(routine_club_members: { status: :active })
                        .distinct

    @monthly_rankings = active_members.map { |u| { user: u, score: u.rufa_club_score } }
                                      .sort_by { |r| -r[:score] }
                                      .take(20) # Top 20 for full leaderboard

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

      # 3. Cheer Count (Mock or Real based on claps)
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

      # 4. Growth Analytics (Real Data)
      # Weekly: Last 7 days completion rate
      @weekly_data = (0..6).map do |days_ago|
        date = Date.current - days_ago.days
        routines = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
        total = routines.count
        completed = routines.select { |r| r.completions.exists?(created_at: date.all_day) }.count
        total.positive? ? ((completed.to_f / total) * 100).round : 0
      end.reverse

      # Monthly: Last 4 weeks completion rate
      @monthly_data = (0..3).map do |weeks_ago|
        week_start = Date.current.beginning_of_week - weeks_ago.weeks
        week_end = week_start + 6.days

        total_days = 0
        completed_days = 0

        (week_start..week_end).each do |date|
          routines = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
          next if routines.empty?

          total_days += routines.count
          completed_days += routines.select { |r| r.completions.exists?(created_at: date.all_day) }.count
        end

        total_days.positive? ? ((completed_days.to_f / total_days) * 100).round : 0
      end.reverse

      # Yearly: This year's monthly completion rates (up to current month)
      current_month = Date.current.month
      @yearly_data = (1..current_month).map do |month|
        month_start = Date.new(Date.current.year, month, 1)
        month_end = [ month_start.end_of_month, Date.current ].min

        total_days = 0
        completed_days = 0

        (month_start..month_end).each do |date|
          routines = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
          next if routines.empty?

          total_days += routines.count
          completed_days += routines.select { |r| r.completions.exists?(created_at: date.all_day) }.count
        end

        total_days.positive? ? ((completed_days.to_f / total_days) * 100).round : 0
      end

      # Calculate current period completion rate
      @weekly_completion = @weekly_data.any? ? (@weekly_data.sum.to_f / @weekly_data.size).round : 0
      @monthly_completion = @monthly_data.any? ? (@monthly_data.sum.to_f / @monthly_data.size).round : 0
      @yearly_completion = @yearly_data.any? ? (@yearly_data.sum.to_f / @yearly_data.size).round : 0

      # Calculate growth compared to previous period
      @weekly_growth = @weekly_data.size >= 2 ? @weekly_data[-1] - @weekly_data[-2] : 0
      @monthly_growth = @monthly_data.size >= 2 ? @monthly_data[-1] - @monthly_data[-2] : 0
      @yearly_growth = @yearly_data.size >= 2 ? @yearly_data[-1] - @yearly_data[-2] : 0
    end
  end

  def notifications
    if current_user.notifications.none? && !session[:notifications_cleared]
      # Create mock notifications for demo purposes
      current_user.notifications.create!([
        { notification_type: :announcement, title: "루파님, 환영합니다! 🚀", content: "성장에 진심인 루파님을 위해 '루틴 파인더스'가 준비한 첫 선물을 확인해보세요.", created_at: Time.current },
        { notification_type: :badge_award, title: "새로운 배지 획득! 🏆", content: "'첫걸음' 배지를 획득하셨습니다. 성취 리포트에서 확인해보세요.", created_at: 2.hours.ago },
        { notification_type: :reminder, title: "루틴 체크 시간이 얼마 남지 않았어요 ✨", content: "오늘 설정하신 '물 2L 마시기' 루틴, 지금 바로 인증하고 루파들의 응원을 받아보세요.", created_at: 1.day.ago },
        { notification_type: :approval, title: "챌린지 입성 완료! ✅", content: "'새벽 6시 기상' 챌린지 신청이 승인되었습니다. 멋진 팀원들이 기다리고 있어요!", created_at: 2.days.ago }
      ])
    end

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

  def live
    @active_members = User.order("RANDOM()").limit(22)
    @current_club = RoutineClub.official.first
    @is_club_member = current_user&.routine_club_members&.active&.exists?
  end

  def lecture_intro
    @hide_nav = true
    @is_club_member = current_user&.routine_club_members&.active&.exists?
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
    @routine_club = RoutineClub.order(created_at: :desc).first
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

  def update_profile
    if current_user
      update_params = {}
      update_params[:nickname] = params[:nickname] if params[:nickname].present?
      update_params[:bio] = params[:bio] if params[:bio].present?

      # Handle profile image upload
      if params[:profile_image].present?
        update_params[:profile_image] = params[:profile_image]
      end

      if current_user.update(update_params)
        redirect_to prototype_my_path, notice: "프로필이 성공적으로 업데이트되었습니다!"
      else
        redirect_to prototype_my_path, alert: "프로필 업데이트에 실패했습니다."
      end
    else
      redirect_to prototype_login_path, alert: "로그인이 필요합니다."
    end
  end

  private

  def set_shared_data
    @official_club = RoutineClub.official.first
    @new_badges = current_user ? current_user.user_badges.where(is_viewed: false).includes(:badge) : []
  end
end
