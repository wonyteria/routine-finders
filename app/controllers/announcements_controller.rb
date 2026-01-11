class AnnouncementsController < ApplicationController
  before_action :require_login
  before_action :set_parent
  before_action :require_host

  def create
    @announcement = @parent.announcements.build(announcement_params)
    if @announcement.save
      redirect_back fallback_location: root_path, notice: "공지사항이 등록되었습니다."
    else
      redirect_back fallback_location: root_path, alert: "공지사항 등록에 실패했습니다."
    end
  end

  def destroy
    @announcement = @parent.announcements.find(params[:id])
    @announcement.destroy
    redirect_back fallback_location: root_path, notice: "공지사항이 삭제되었습니다."
  end

  private

  def set_parent
    if params[:routine_club_id]
      @parent = RoutineClub.find(params[:routine_club_id])
    elsif params[:challenge_id]
      @parent = Challenge.find(params[:challenge_id])
    end
  end

  def require_host
    if @parent.is_a?(RoutineClub)
      redirect_to @parent, alert: "권한이 없습니다." unless @parent.host == current_user || current_user.admin?
    elsif @parent.is_a?(Challenge)
      redirect_to @parent, alert: "권한이 없습니다." unless @parent.host == current_user || current_user.admin?
    end
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content)
  end
end
