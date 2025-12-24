module Api
  module V1
    class NotificationsController < BaseController
      before_action :require_login

      def index
        notifications = current_user.notifications.recent
        render json: notifications
      end

      def mark_as_read
        notification = current_user.notifications.find(params[:id])
        notification.mark_as_read!
        render json: notification
      end

      def mark_all_as_read
        current_user.notifications.unread.update_all(is_read: true)
        head :no_content
      end
    end
  end
end
