class RoutineClubGatheringsController < ApplicationController
  before_action :require_login
  before_action :set_routine_club
  before_action :require_host

  def create
    @gathering = @routine_club.gatherings.build(gathering_params)
    if @gathering.save
      redirect_back fallback_location: manage_routine_club_path(@routine_club, tab: "community"), notice: "모임이 생성되었습니다."
    else
      redirect_back fallback_location: manage_routine_club_path(@routine_club, tab: "community"), alert: "모임 생성에 실패했습니다."
    end
  end

  def destroy
    @gathering = @routine_club.gatherings.find(params[:id])
    @gathering.destroy
    redirect_back fallback_location: manage_routine_club_path(@routine_club, tab: "community"), notice: "모임이 삭제되었습니다."
  end

  private

  def set_routine_club
    @routine_club = RoutineClub.find(params[:routine_club_id])
  end

  def require_host
    redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host == current_user || current_user.admin?
  end

  def gathering_params
    params.require(:routine_club_gathering).permit(:title, :description, :gathering_at, :gathering_type, :location, :max_attendees)
  end
end
