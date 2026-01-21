module Admin
  class BannersController < BaseController
    before_action :set_banner, only: [:edit, :update, :destroy]

    def index
      @banners = Banner.all.order(priority: :desc)
    end

    def new
      @banner = Banner.new
    end

    def create
      @banner = Banner.new(banner_params)
      if @banner.save
        redirect_to admin_banners_path, notice: "새 배너가 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @banner.update(banner_params)
        redirect_to admin_banners_path, notice: "배너 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @banner.destroy
      redirect_to admin_banners_path, notice: "배너가 삭제되었습니다."
    end

    private

    def set_banner
      @banner = Banner.find(params[:id])
    end

    def banner_params
      params.require(:banner).permit(:title, :subtitle, :link_url, :active, :priority, :banner_type, :badge_text, :image)
    end
  end
end
