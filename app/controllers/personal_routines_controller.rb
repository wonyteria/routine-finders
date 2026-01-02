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

    # 루틴 클럽 (유료)
    @routine_clubs = RoutineClub.recruiting_clubs.includes(:host, :members).order(created_at: :desc).limit(6)
    @my_club_memberships = current_user.routine_club_members.includes(:routine_club).where(status: [ :active, :warned ])
    @pending_payments = current_user.routine_club_members.where(payment_status: :pending)

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
