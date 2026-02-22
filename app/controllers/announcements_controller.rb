class AnnouncementsController < ApplicationController
  before_action :require_login
  before_action :set_parent
  before_action :require_host

  def new
    flash.discard # Clear any existing flash messages
    @announcement = @parent.announcements.build
    @challenge = @parent if @parent.is_a?(Challenge)
    @routine_club = @parent if @parent.is_a?(RoutineClub)
  end

  def create
    @announcement = @parent.announcements.build(announcement_params)
    @challenge = @parent if @parent.is_a?(Challenge)
    @routine_club = @parent if @parent.is_a?(RoutineClub)

    if @announcement.save
      # Send Notifications to all participants/members
      if @challenge
        @challenge.participants.each do |participant|
          Notification.create!(
            user: participant.user,
            title: "[공지] #{@challenge.title}",
            content: @announcement.title,
            link: challenge_path(@challenge, tab: "announcements", source: "prototype"),
            notification_type: :announcement
          )
        end
      elsif @routine_club
        @routine_club.routine_club_members.where(status: :active).each do |member|
          Notification.create!(
            user: member.user,
            title: "[공지] #{@routine_club.title}",
            content: @announcement.title,
            link: routine_club_path(@routine_club, tab: "announcements", source: "prototype"),
            notification_type: :announcement
          )
        end
      end

      redirect_to (params[:source] == "prototype" && @challenge) ? hosted_challenge_path(@challenge, tab: "announcements", source: "prototype") : request.referer || root_path, notice: "공지사항이 등록 및 알림 발송되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @announcement = @parent.announcements.find(params[:id])
    @challenge = @parent if @parent.is_a?(Challenge)
    @routine_club = @parent if @parent.is_a?(RoutineClub)
  end

  def update
    @announcement = @parent.announcements.find(params[:id])
    @challenge = @parent if @parent.is_a?(Challenge)
    @routine_club = @parent if @parent.is_a?(RoutineClub)

    if @announcement.update(announcement_params)
      redirect_to (params[:source] == "prototype" && @challenge) ? hosted_challenge_path(@challenge, tab: "announcements", source: "prototype") : request.referer || root_path, notice: "공지사항이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement = @parent.announcements.find(params[:id])
    @announcement.destroy
    @challenge = @parent if @parent.is_a?(Challenge)

    redirect_to (params[:source] == "prototype" && @challenge) ? hosted_challenge_path(@challenge, tab: "announcements", source: "prototype") : request.referer || root_path, notice: "공지사항이 삭제되었습니다."
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
