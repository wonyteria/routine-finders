class PersonalRoutinesController < ApplicationController
  before_action :require_login
  before_action :set_routine, only: [ :toggle, :destroy ]

  def index
    @personal_routines = current_user.personal_routines.order(created_at: :desc)
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
        format.html { redirect_to root_path, notice: "루틴이 추가되었습니다!" }
        format.turbo_stream
      end
    else
      redirect_to root_path, alert: "루틴 추가에 실패했습니다."
    end
  end

  def toggle
    @routine.toggle_completion!

    respond_to do |format|
      format.html { redirect_to root_path }
      format.turbo_stream
    end
  end

  def destroy
    @routine.destroy

    respond_to do |format|
      format.html { redirect_to root_path, notice: "루틴이 삭제되었습니다." }
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
