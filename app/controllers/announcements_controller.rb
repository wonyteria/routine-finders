class AnnouncementsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :require_host
  before_action :set_announcement, only: [ :edit, :update, :destroy ]

  def new
    @announcement = @challenge.announcements.build
  end

  def create
    @announcement = @challenge.announcements.build(announcement_params)

    if @announcement.save
      # Notify participants about new announcement
      notify_participants

      redirect_to hosted_challenge_path(@challenge, tab: "announcements"), notice: "공지사항이 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to hosted_challenge_path(@challenge, tab: "announcements"), notice: "공지사항이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    redirect_to hosted_challenge_path(@challenge, tab: "announcements"), notice: "공지사항이 삭제되었습니다."
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_announcement
    @announcement = @challenge.announcements.find(params[:id])
  end

  def require_host
    unless current_user.id == @challenge.host_id
      redirect_to @challenge, alert: "호스트만 접근할 수 있습니다."
    end
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content)
  end

  def notify_participants
    @challenge.participants.each do |participant|
      Notification.create!(
        user: participant.user,
        notification_type: :announcement,
        title: "[공지] #{@challenge.title}",
        content: @announcement.title,
        link: challenge_path(@challenge, tab: "announcements")
      )
    end
  end
end
