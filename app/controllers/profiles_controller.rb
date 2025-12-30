class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @participations = @user.participations.includes(:challenge)
    @hosted_challenges = @user.hosted_challenges.includes(:participants)
    @challenge_applications = @user.challenge_applications.includes(:challenge).order(created_at: :desc)

    # 호스트 통계
    pending_count = VerificationLog.joins(:challenge).where(challenges: { host_id: @user.id }, status: :pending).count
    @host_stats = {
      total_challenges: @hosted_challenges.count,
      total_participants: @hosted_challenges.sum(:current_participants),
      active_challenges: @hosted_challenges.active.count,
      pending_verifications: pending_count
    }

    # 개최 챌린지별 대기 중인 인증 건수 (N+1 방지)
    @hosted_pending_counts = VerificationLog
      .where(challenge_id: @hosted_challenges.pluck(:id), status: :pending)
      .group(:challenge_id)
      .count
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "프로필이 업데이트되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def save_account
    @user = current_user
    if @user.update(
      saved_bank_name: params[:bank_name],
      saved_account_number: params[:account_number],
      saved_account_holder: params[:account_holder]
    )
      render json: { status: "success", message: "계좌 정보가 저장되었습니다." }
    else
      render json: { status: "error", message: "저장에 실패했습니다." }, status: :unprocessable_entity
    end
  end

  def get_account
    @user = current_user
    if @user.has_saved_account?
      render json: {
        status: "success",
        bank_name: @user.saved_bank_name,
        account_number: @user.saved_account_number,
        account_holder: @user.saved_account_holder
      }
    else
      render json: { status: "error", message: "저장된 계좌 정보가 없습니다." }, status: :not_found
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :bio,
      :saved_bank_name,
      :saved_account_number,
      :saved_account_holder,
      sns_links: [ :instagram, :threads, :blog, :youtube, :twitter ]
    )
  end
end
