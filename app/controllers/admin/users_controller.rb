module Admin
  class UsersController < BaseController
    before_action :require_super_admin
    before_action :set_user, only: [ :show, :edit, :update, :destroy, :toggle_status ]

    def index
      @users = User.all.order(created_at: :desc)

      # 검색 필터
      if params[:query].present?
        q = "%#{params[:query]}%"
        @users = @users.where("nickname LIKE ? OR email LIKE ?", q, q)
      end

      # 역할 필터
      if params[:role].present?
        @users = @users.where(role: params[:role])
      end

      @total_count = @users.count
    end

    def show
      @stats = {
        challenges_joined: @user.participations.count,
        challenges_hosted: @user.hosted_challenges.count,
        total_routines: @user.personal_routines.count,
        completions: @user.total_routine_completions
      }
      @recent_activities = @user.rufa_activities.order(created_at: :desc).limit(10)
    end

    def update
      if @user == current_user && user_params[:role].present? && user_params[:role] != "super_admin"
        redirect_to admin_user_path(@user), alert: "자신의 관리자 권한은 해제할 수 없습니다."
        return
      end

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "사용자 정보가 성공적으로 업데이트되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_status
      if @user == current_user
        redirect_to admin_users_path, alert: "자신의 상태는 변경할 수 없습니다."
        return
      end

      if @user.deleted_at.nil?
        @user.update(deleted_at: Time.current)
        notice = "사용자 계정이 정지되었습니다."
      else
        @user.update(deleted_at: nil)
        notice = "사용자 계정이 활성화되었습니다."
      end

      redirect_to admin_users_path, notice: notice
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:nickname, :email, :role, :level, :wallet_balance)
    end
  end
end
