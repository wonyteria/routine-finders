module Admin
  class UsersController < BaseController
    before_action :require_super_admin
    before_action :set_user, only: [ :show, :edit, :update, :destroy ]

    def index
      @users = User.order(created_at: :desc)
      if params[:q].present?
        sanitized_q = "%#{sanitize_sql_like(params[:q])}%"
        @users = @users.where("nickname LIKE ? OR email LIKE ?", sanitized_q, sanitized_q)
      end
      @users = @users.page(params[:page]).per(20) if @users.respond_to?(:page)
    end

    def show
      @hosted_challenges = @user.hosted_challenges.order(created_at: :desc).limit(5)
      @participations = @user.participations.includes(:challenge).order(created_at: :desc).limit(5)
      @personal_routines = @user.personal_routines.order(created_at: :desc).limit(5)
    end

    def edit
    end

    def update
      # Prevent self-demotion from super_admin if attempting to change role
      if user_params[:role].present? && @user == current_user
        redirect_to admin_user_path(@user), alert: "자기 자신의 역할은 변경할 수 없습니다."
        return
      end

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "사용자 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "자기 자신은 삭제할 수 없습니다."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "사용자가 삭제되었습니다."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:nickname, :email, :level, :total_exp, :wallet_balance, :is_featured_host, :role)
    end
  end
end
