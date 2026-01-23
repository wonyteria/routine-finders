module Admin
  class PersonalRoutinesController < BaseController
    before_action :require_super_admin
    before_action :set_personal_routine, only: [ :show, :destroy ]

    def index
      @personal_routines = PersonalRoutine.includes(:user).order(created_at: :desc)
      if params[:q].present?
        sanitized_q = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q])}%"
        @personal_routines = @personal_routines.where("title LIKE ?", sanitized_q)
      end
      @personal_routines = @personal_routines.page(params[:page]).per(20) if @personal_routines.respond_to?(:page)
    end

    def show
    end

    def destroy
      @personal_routine.destroy
      redirect_to admin_personal_routines_path, notice: "개인 루틴이 삭제되었습니다."
    end

    private

    def set_personal_routine
      @personal_routine = PersonalRoutine.find(params[:id])
    end
  end
end
