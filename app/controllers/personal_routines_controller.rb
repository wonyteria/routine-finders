class PersonalRoutinesController < ApplicationController
  before_action :require_login
  before_action :set_routine, only: [ :edit, :update, :toggle, :destroy ]

  def index
    # 개인 루틴 (무료)
    # 배지 모달이 화면을 가리는 현상을 방지하기 위해 자동 조회 처리
    current_user.user_badges.where(is_viewed: false).update_all(is_viewed: true) if logged_in?

    @personal_routines = current_user.personal_routines.includes(:completions).order(created_at: :desc)
    @monthly_completions = current_user.personal_routines.joins(:completions)
                                       .where(personal_routine_completions: { completed_on: Date.current.beginning_of_month..Date.current.end_of_month })

    # 루파 클럽 공식 생성 (없을 경우)
    if RoutineClub.official.none?
      admin = User.find_by(role: :admin) || User.first
      RoutineClub.create!(
        title: "루파 클럽 공식",
        description: "루틴 파인더스가 직접 운영하는 단 하나의 공식 루파 클럽입니다. 압도적 성장을 위한 최적의 시스템!",
        monthly_fee: 5000,
        min_duration_months: 3,
        start_date: Date.current,
        end_date: Date.current + 1.year,
        is_official: true,
        host: admin,
        category: "건강·운동"
      )
    end

    # 루파 클럽 (유료) 관련 통계 및 랭킹
    @official_club = RoutineClub.official.first
    @routine_clubs = RoutineClub.recruiting_clubs.includes(:host, :members).order(created_at: :desc).limit(6)
    @my_club_memberships = current_user.routine_club_members.includes(:routine_club).where(status: [ :active, :warned ])
    @pending_payments = current_user.routine_club_members.where(payment_status: :pending)

    # 루파 클럽 공식 공지사항
    if Announcement.where(routine_club: @official_club).none?
      @official_club.announcements.create!(title: "루파 클럽에 오신 것을 환영합니다! 목표 설정을 시작해보세요.", body: "내용")
      @official_club.announcements.create!(title: "1월 오프라인 정기 모임 일정 안내", body: "내용")
    end
    @rufa_announcements = Announcement.where(routine_club: @official_club).recent.limit(5)

    # 유저 목표 (단기/중기/장기)
    @user_goals = current_user.user_goals.index_by(&:goal_type)
    @short_term_goal = @user_goals["short_term"]&.body
    @mid_term_goal = @user_goals["mid_term"]&.body
    @long_term_goal = @user_goals["long_term"]&.body

    # 루파 클럽 멤버 랭킹 (상위 10명)
    @rufa_rankings = User.joins(:routine_club_members)
                         .where(routine_club_members: { status: :active })
                         .distinct
                         .map { |u| { user: u, score: u.rufa_club_score } }
                         .sort_by { |r| -r[:score] }
                         .take(10)

    # 현재 사용자의 루파 상태
    @current_log_rate = current_user.monthly_routine_log_rate
    @current_achievement_rate = current_user.monthly_achievement_rate

    @recommended_routines = [
      { title: "종합 영양제 먹기", category: "HEALTH", icon: "💊", color: "text-rose-400" },
      { title: "물 2L 마시기", category: "HEALTH", icon: "💧", color: "text-blue-400" },
      { title: "스트레칭 5분", category: "HEALTH", icon: "🧘", color: "text-emerald-400" },
      { title: "안약 넣기", category: "LIFE", icon: "👀", color: "text-sky-400" },
      { title: "책상 정리하기", category: "PRODUCTIVITY", icon: "🧹", color: "text-orange-400" },
      { title: "내일 할 일 계획", category: "PRODUCTIVITY", icon: "📝", color: "text-purple-400" },
      { title: "스킨케어 루틴", category: "LIFE", icon: "✨", color: "text-pink-400" },
      { title: "감사 일기 쓰기", category: "MIND", icon: "✍️", color: "text-yellow-400" },
      { title: "자기 전 폰 안보기", category: "LIFE", icon: "📱", color: "text-indigo-400" },
      { title: "스쿼트 20개", category: "HEALTH", icon: "🏋️", color: "text-orange-500" }
    ]
  end

  def create
    @routine = current_user.personal_routines.build(routine_params)

    if @routine.save
      respond_to do |format|
        format.html { redirect_to personal_routines_path, notice: "루틴이 추가되었습니다!" }
        format.turbo_stream
      end
    else
      redirect_to personal_routines_path, alert: "루틴 추가에 실패했습니다."
    end
  end

  def edit
  end

  def update
    if @routine.update(routine_params)
      respond_to do |format|
        format.html { redirect_to personal_routines_path, notice: "루틴이 수정되었습니다!" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle
    @routine.toggle_completion!

    respond_to do |format|
      format.html { redirect_to personal_routines_path }
      format.turbo_stream
    end
  end

  def update_goals
    [ :short_term, :mid_term, :long_term ].each do |type|
      if params[type].present?
        goal = current_user.user_goals.find_or_initialize_by(goal_type: type)
        goal.update(body: params[type])
      end
    end
    redirect_to personal_routines_path(tab: "club"), notice: "목표가 저장되었습니다."
  end

  def destroy
    @routine.destroy

    respond_to do |format|
      format.html { redirect_to personal_routines_path, notice: "루틴이 삭제되었습니다." }
      format.turbo_stream
    end
  end

  private

  def set_routine
    @routine = current_user.personal_routines.find(params[:id])
  end

  def routine_params
    params.require(:personal_routine).permit(:title, :icon, :color, :category, days: [])
  end
end
