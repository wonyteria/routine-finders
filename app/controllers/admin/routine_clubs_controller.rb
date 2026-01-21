module Admin
  class RoutineClubsController < BaseController
    before_action :require_super_admin
    before_action :set_routine_club, only: [ :show, :edit, :update, :destroy ]

    def index
      @routine_clubs = RoutineClub.all.order(created_at: :desc)
    end

    def show
    end

    def new
      @routine_club = RoutineClub.new(
        host: current_user,
        start_date: Date.current,
        end_date: Date.current + 3.months,
        min_duration_months: 3
      )
    end

    def edit
    end

    def create
      @routine_club = RoutineClub.new(routine_club_params)
      # If host_id is not provided, default to current_user
      @routine_club.host ||= current_user

      if @routine_club.save
        redirect_to admin_routine_clubs_path, notice: "루틴 클럽이 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @routine_club.update(routine_club_params)
        redirect_to admin_routine_clubs_path, notice: "루틴 클럽이 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @routine_club.destroy
      redirect_to admin_routine_clubs_path, notice: "루틴 클럽이 삭제되었습니다."
    end

    private

    def set_routine_club
      @routine_club = RoutineClub.find(params[:id])
    end

    def routine_club_params
      params.require(:routine_club).permit(
        :title, :description, :category, :monthly_fee, :min_duration_months,
        :start_date, :end_date, :status, :is_official, :max_members, :thumbnail,
        :host_id, :zoom_link, :special_lecture_link
      )
    end
  end
end
