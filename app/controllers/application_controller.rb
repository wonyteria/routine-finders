class ApplicationController < ActionController::Base
  layout :set_layout
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  before_action :set_unviewed_badges
  before_action :set_pending_welcome_membership

  helper_method :current_user, :logged_in?, :pending_welcome_membership

  private

  def set_unviewed_badges
    if logged_in?
      @unviewed_badges = current_user.user_badges.where(is_viewed: false).includes(:badge)
    else
      @unviewed_badges = []
    end
  end

  def set_pending_welcome_membership
    if logged_in?
      @pending_welcome_membership = current_user.routine_club_members
                                                 .where(payment_status: :confirmed, welcomed: false)
                                                 .includes(:routine_club)
                                                 .first
    else
      @pending_welcome_membership = nil
    end
  end

  def pending_welcome_membership
    @pending_welcome_membership
  end

  def current_user
    @_current_user ||= session[:user_id] ? User.active.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    unless current_user
      store_location
      redirect_to root_path, alert: "로그인이 필요합니다."
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "해당 기능은 루틴 파인더스 관리자만 이용 가능합니다."
    end
  end

  def require_super_admin
    unless current_user&.super_admin?
      redirect_to root_path, alert: "해당 기능은 총괄 관리자만 이용 가능합니다."
    end
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get? || request.head?
  end

  def redirect_back_or(default)
    redirect_to(session[:forwarding_url] || default)
    session.delete(:forwarding_url)
  end

  def set_layout
    params[:source] == "prototype" ? "prototype" : "application"
  end

  def default_url_options
    params[:source] == "prototype" ? { source: "prototype" } : {}
  end
end
