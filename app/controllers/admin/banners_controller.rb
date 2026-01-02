module Admin
  class BannersController < BaseController
    before_action :set_banner, only: [ :show, :edit, :update, :destroy ]

    def index
      @banners = Banner.ordered
    end

    def show
    end

    def new
      @banner = Banner.new(active: true, priority: 0)
    end

    def edit
    end

    def create
      @banner = Banner.new(banner_params)

      if @banner.save
        redirect_to admin_banners_path, notice: "배너가 성공적으로 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @banner.update(banner_params)
        redirect_to admin_banners_path, notice: "배너가 성공적으로 수정되었습니다."
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
      params.require(:banner).permit(:title, :subtitle, :badge_text, :link_url, :banner_type, :active, :priority, :image)
    end
  end
end
