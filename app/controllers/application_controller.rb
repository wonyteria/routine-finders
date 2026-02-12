class ApplicationController < ActionController::Base
  layout :set_layout
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  before_action :set_unviewed_badges
  before_action :set_pending_welcome_membership
  around_action :set_time_zone

  helper_method :current_user, :logged_in?, :pending_welcome_membership

  private

  def set_time_zone(&block)
    tz = current_user&.time_zone || "Seoul"
    Time.use_zone(tz, &block)
  end

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
      if params[:source] == "web"
        redirect_to root_path, alert: "로그인이 필요합니다."
      else
        redirect_to prototype_login_path, alert: "로그인이 필요합니다."
      end
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

  def require_rufa_club_member
    unless current_user&.is_rufa_club_member?
      flash[:is_rufa_pending] = true if current_user&.is_rufa_pending?
      redirect_to guide_routine_clubs_path, alert: "루파 클럽 리포트는 멤버 전용 혜택입니다. 루파 클럽에 합류하고 리포트를 받아보세요!"
    end
  end

  def require_can_create_challenge
    permission = PermissionService.new(current_user)
    unless permission.can_create_challenge?
      if current_user&.is_rufa_pending?
        flash[:is_rufa_pending] = true
        msg = "클럽 멤버십 승인 대기 중입니다. 승인 완료 후 개설이 가능합니다."
      else
        msg = "챌린지 개설 권한이 없습니다. (루파 클럽 멤버 또는 레벨 10 이상 가능)"
      end
      redirect_to (params[:source] == "prototype" ? prototype_explore_path : challenges_path), alert: msg
    end
  end

  def require_can_create_gathering
    permission = PermissionService.new(current_user)
    unless permission.can_create_gathering?
      if current_user&.is_rufa_pending?
        flash[:is_rufa_pending] = true
        msg = "클럽 멤버십 승인 대기 중입니다. 승인 완료 후 개설이 가능합니다."
      else
        msg = "모임 개설 권한이 없습니다. (루파 클럽 멤버 또는 레벨 5 이상 가능)"
      end
      redirect_to (params[:source] == "prototype" ? prototype_explore_path : challenges_path), alert: msg
    end
  end

  def store_location
    session[:forwarding_url] = request.original_url if (request.get? || request.head?) && !request.xhr?
  end

  def redirect_back_or(default)
    url = session[:forwarding_url] || default
    session.delete(:forwarding_url)
    redirect_to(url)
  end

  def set_layout
    "prototype"
  end

  def default_url_options
    {}
  end
end
