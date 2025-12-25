module Admin
  class BaseController < ApplicationController
    before_action :require_admin
    layout "admin"

    private

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: "관리자 권한이 필요합니다."
      end
    end
  end
end
