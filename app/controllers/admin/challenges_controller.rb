class Admin::ChallengesController < Admin::BaseController
  before_action :set_challenge, only: [:show, :edit, :update, :destroy]

  def index
    @challenges = Challenge.all.order(created_at: :desc)

    if params[:status].present?
      @challenges = @challenges.where(status: params[:status])
    end

    if params[:query].present?
      @challenges = @challenges.where("title LIKE ?", "%#{params[:query]}%")
    end
  end

  def show
    @participants = @challenge.participations.includes(:user)
    @verification_logs = @challenge.verification_logs.order(created_at: :desc).limit(20)
  end

  def update
    if @challenge.update(challenge_params)
      redirect_to admin_challenge_path(@challenge), notice: "챌린지 정보가 수정되었습니다."
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
    params.require(:challenge).permit(:title, :description, :status, :start_date, :end_date, :amount)
  end
end
