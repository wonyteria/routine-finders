class PrototypeController < ApplicationController
  layout "prototype"
  before_action :set_shared_data

  def home
    @todays_routines = current_user ? current_user.personal_routines.select { |r| (r.days || []).include?(Date.current.wday.to_s) } : []
    @completed_count = @todays_routines.select(&:completed_today?).count
    @progress = @todays_routines.any? ? (@completed_count.to_f / @todays_routines.count * 100).to_i : 0

    # Check for active club membership
    @membership = current_user&.routine_club_members&.active&.first
    @is_club_member = @membership.present?

    # Fetch recent reflections for the rotating UI
    @recent_reflections = RufaActivity.where(activity_type: [ "routine_record", "reflection" ]).order(created_at: :desc).limit(10)

    # Fetch user's hosted/joined content for dashboard
    if current_user
      @hosted_challenges = Challenge.where(host: current_user).order(created_at: :desc).limit(2)
      @joined_challenges = current_user.challenges.active.limit(2)
    else
      @hosted_challenges = []
      @joined_challenges = []
    end
  end

  def explore
    @featured_club = RoutineClub.active_clubs.order(created_at: :desc).first

    # Categorize for better discovery
    real_active = Challenge.active.where(mode: :online).order(current_participants: :desc).limit(6).to_a
    real_gatherings = Challenge.active.where(mode: :offline).order(created_at: :desc).limit(4).to_a

    # Fill with dummy data if not enough real ones (for prototyping/demo)
    dummies = Challenge.generate_dummy_challenges

    @active_challenges = (real_active + dummies.select { |d| d.mode == "online" }).uniq { |c| c.title }.first(6)
    @gatherings = (real_gatherings + dummies.select { |d| d.mode == "offline" }).uniq { |c| c.title }.first(4)
  end

  def synergy
    @top_users = User.active.limit(3) # Placeholder for Hall of Fame
    @recent_activities = RufaActivity.order(created_at: :desc).limit(10)
  end

  def my
    @total_activities = current_user&.total_routine_completions || 0
    @current_streak = current_user&.personal_routines&.maximum(:current_streak) || 0
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

  private

  def set_shared_data
    nil unless current_user
    # Any data needed across all tabs
  end
end
