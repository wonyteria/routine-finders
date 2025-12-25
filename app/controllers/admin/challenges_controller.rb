module Admin
  class ChallengesController < BaseController
    before_action :set_challenge, only: [ :show, :edit, :update, :destroy ]

    def index
      @challenges = Challenge.includes(:host).order(created_at: :desc)
      if params[:q].present?
        sanitized_q = "%#{sanitize_sql_like(params[:q])}%"
        @challenges = @challenges.where("title LIKE ?", sanitized_q)
      end
      @challenges = @challenges.where(mode: params[:mode]) if params[:mode].present?
      @challenges = @challenges.page(params[:page]).per(20) if @challenges.respond_to?(:page)
    end

    def show
      @participants = @challenge.participants.includes(:user).order(created_at: :desc)
    end

    def edit
    end

    def update
      if @challenge.update(challenge_params)
        redirect_to admin_challenge_path(@challenge), notice: "챌린지가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @challenge.destroy
      redirect_to admin_challenges_path, notice: "챌린지가 삭제되었습니다."
    end

    private

    def set_challenge
      @challenge = Challenge.find(params[:id])
    end

    def challenge_params
      params.require(:challenge).permit(
        :title, :description, :purpose, :start_date, :end_date,
        :mode, :entry_type, :cost_type, :verification_type,
        :is_official, :max_participants
      )
    end
  end
end
