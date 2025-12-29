class ReviewsController < ApplicationController
  before_action :require_login, except: [ :index ]
  before_action :set_challenge
  before_action :set_review, only: [ :edit, :update, :destroy ]
  before_action :authorize_review, only: [ :edit, :update, :destroy ]
  before_action :check_can_review, only: [ :new, :create ]

  def index
    @reviews = @challenge.reviews.includes(:user).recent
  end

  def new
    @review = @challenge.reviews.new
  end

  def create
    @review = @challenge.reviews.new(review_params)
    @review.user = current_user

    if @review.save
      redirect_to challenge_path(@challenge), notice: "리뷰가 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to challenge_path(@challenge), notice: "리뷰가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to challenge_path(@challenge), notice: "리뷰가 삭제되었습니다."
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_review
    @review = @challenge.reviews.find(params[:id])
  end

  def authorize_review
    unless @review.user == current_user || current_user.admin?
      redirect_to challenge_path(@challenge), alert: "권한이 없습니다."
    end
  end

  def check_can_review
    # 이미 리뷰를 작성했는지 확인
    if @challenge.reviews.exists?(user: current_user)
      redirect_to challenge_path(@challenge), alert: "이미 리뷰를 작성하셨습니다."
      return
    end

    # 챌린지에 참여한지 7일이 지났는지 확인
    participation = @challenge.participants.find_by(user: current_user)
    if participation.nil?
      redirect_to challenge_path(@challenge), alert: "챌린지에 참여한 사용자만 리뷰를 작성할 수 있습니다."
    elsif participation.joined_at > 7.days.ago
      redirect_to challenge_path(@challenge), alert: "챌린지 참여 후 7일이 지나야 리뷰를 작성할 수 있습니다."
    end
  end

  def review_params
    params.require(:review).permit(:rating, :content)
  end
end
