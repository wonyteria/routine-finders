class Admin::BaseController < ApplicationController
  before_action :require_login
  before_action :ensure_admin_user
  layout "admin"

  private

  def ensure_admin_user
    unless current_user&.super_admin?
      flash[:alert] = "관리자 권한이 필요합니다."
      redirect_to root_path
    end
  end
end
