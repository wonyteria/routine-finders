class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = current_user.notifications.recent
  end

  def mark_as_read
    notification = current_user.notifications.find(params[:id])
    notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path) }
      format.turbo_stream
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(is_read: true)
    redirect_to notifications_path, notice: "모든 알림을 읽음 처리했습니다."
  end
end
