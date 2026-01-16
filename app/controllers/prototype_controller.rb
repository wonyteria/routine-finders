class PrototypeController < ApplicationController
  layout "prototype"
  before_action :set_shared_data

  def home
    # 1. Total Daily Tasks Calculation (Routines + Challenges + Gatherings)
    @todays_routines = current_user ? current_user.personal_routines.select { |r| (r.days || []).include?(Date.current.wday.to_s) } : []
    @joined_challenges_active = current_user ? current_user.participations.active.joins(:challenge).where(challenges: { mode: :online }) : []
    @todays_gatherings = current_user ? current_user.participations.active.joins(:challenge).where(challenges: { mode: :offline, start_date: Date.current }) : []

    # Counts
    routine_total = @todays_routines.count
    challenge_total = @joined_challenges_active.count
    gathering_total = @todays_gatherings.count
    @total_task_count = routine_total + challenge_total + gathering_total

    # Completed Counts
    routine_done = @todays_routines.select(&:completed_today?).count
    # Simplified: assume verification_logs for today exists for completed challenges
    challenge_done = current_user ? VerificationLog.where(participant: current_user.participations, created_at: Date.current.all_day).pluck(:participant_id).uniq.count : 0
    # Simplified: assume attendance for today exists for gatherings
    gathering_done = current_user ? @todays_gatherings.select { |p| p.attended_on?(Date.current) rescue false }.count : 0 # fallback to false for prototype

    @completed_count = routine_done + challenge_done + gathering_done
    @progress = @total_task_count.positive? ? (@completed_count.to_f / @total_task_count * 100).to_i : 0

    # 2. Check for active club membership
    @membership = current_user&.routine_club_members&.active&.first
    @is_club_member = @membership.present?

    # 3. Live Feed Data
    @recent_reflections = RufaActivity.where(activity_type: [ "routine_record", "reflection" ]).order(created_at: :desc).limit(10)
    @recent_challenge_joins = Participant.joins(:challenge).where(challenges: { mode: :online }).order(created_at: :desc).limit(5)
    @recent_gathering_joins = Participant.joins(:challenge).where(challenges: { mode: :offline }).order(created_at: :desc).limit(5)

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
    challenges_query = Challenge.where(mode: :online).where("end_date >= ?", Date.current)
    gatherings_query = Challenge.where(mode: :offline).where("end_date >= ?", Date.current)

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
    @recent_activities = RufaActivity.order(created_at: :desc).limit(10)
  end

  def my
    @total_activities = current_user&.total_routine_completions || 0
    @current_streak = current_user&.personal_routines&.maximum(:current_streak) || 0
    @current_month_points = current_user&.current_month_points || 0
    @total_platform_score = current_user&.total_platform_score || 0
    @achievements = current_user&.user_badges&.includes(:badge)&.limit(3) || []
  end

  def record
    if current_user && params[:body].present?
      RufaActivity.create!(
        user: current_user,
        activity_type: "routine_record",
        body: params[:body],
        metadata: { source: "prototype" }
      )
      redirect_to prototype_home_path, notice: "오늘의 루틴 성취를 기록했습니다!"
    else
      redirect_to prototype_home_path, alert: "내용을 입력해주세요."
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
    @active_members = User.order("RANDOM()").limit(8)
    @current_club = RoutineClub.official.first
    @is_club_member = current_user&.routine_club_members&.active&.exists?
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

  private

  def set_shared_data
    @official_club = RoutineClub.official.first
  end
end
