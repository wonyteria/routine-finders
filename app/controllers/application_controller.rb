class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  before_action :set_unviewed_badges

  helper_method :current_user, :logged_in?

  private

  def set_unviewed_badges
    if logged_in?
      @unviewed_badges = current_user.user_badges.where(is_viewed: false).includes(:badge)
    else
      @unviewed_badges = []
    end
  end

  def current_user
    @_current_user ||= session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless current_user
      redirect_to root_path, alert: "로그인이 필요합니다."
    end
  end
end
