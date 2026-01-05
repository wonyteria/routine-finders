class RoutineClubAnnouncementsController < ApplicationController
  before_action :require_login
  before_action :set_routine_club
  before_action :require_host

  def create
    @announcement = @routine_club.announcements.build(announcement_params)
    if @announcement.save
      redirect_to manage_routine_club_path(@routine_club), notice: "공지사항이 등록되었습니다."
    else
      redirect_to manage_routine_club_path(@routine_club), alert: "공지사항 등록에 실패했습니다."
    end
  end

  def destroy
    @announcement = @routine_club.announcements.find(params[:id])
    @announcement.destroy
    redirect_to manage_routine_club_path(@routine_club), notice: "공지사항이 삭제되었습니다."
  end

  private

  def set_routine_club
    @routine_club = RoutineClub.find(params[:routine_club_id])
  end

  def require_host
    redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host == current_user
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content)
  end
end
