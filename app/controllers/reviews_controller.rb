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
    if params[:source] == "prototype"
      render layout: "prototype"
    end
  end

  def create
    @review = @challenge.reviews.new(review_params)
    @review.user = current_user

    if @review.save
      redirect_to challenge_path(@challenge, tab: "community", source: params[:source]), notice: "리뷰가 등록되었습니다."
    else
      if params[:source] == "prototype"
        render :new, status: :unprocessable_entity, layout: "prototype"
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
    if @review.edit_count >= 2
      redirect_to challenge_path(@challenge, source: params[:source]), alert: "리뷰는 최대 2회까지만 수정할 수 있습니다."
    end
    if params[:source] == "prototype"
      render layout: "prototype"
    end
  end

  def update
    if @review.edit_count >= 2
      redirect_to challenge_path(@challenge), alert: "리뷰는 최대 2회까지만 수정할 수 있습니다."
      return
    end

    if @review.update(review_params)
      @review.increment!(:edit_count)
      redirect_to challenge_path(@challenge, source: params[:source]), notice: "리뷰가 수정되었습니다. (남은 수정 횟수: #{2 - @review.edit_count}회)"
    else
      if params[:source] == "prototype"
        render :edit, status: :unprocessable_entity, layout: "prototype"
      else
        render :edit, status: :unprocessable_entity
      end
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

    # 참여 기간 확인 (오프라인 모임은 즉시, 온라인 챌린지는 7일 이후)
    participation = @challenge.participants.find_by(user: current_user)
    if participation.nil?
      redirect_to challenge_path(@challenge), alert: "챌린지에 참여한 사용자만 리뷰를 작성할 수 있습니다."
    elsif @challenge.offline?
      if Date.current < @challenge.start_date
        redirect_to challenge_path(@challenge), alert: "리뷰는 모임 시작일 이후부터 작성할 수 있습니다."
      end
    elsif participation.joined_at > 7.days.ago
      redirect_to challenge_path(@challenge), alert: "챌린지 참여 후 7일이 지나야 리뷰를 작성할 수 있습니다."
    end
  end

  def review_params
    params.require(:review).permit(:rating, :content, :message_to_host)
  end
end
