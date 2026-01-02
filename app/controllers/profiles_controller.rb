class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @participations = @user.participations.includes(:challenge).order(created_at: :desc)
    @hosted_challenges = @user.hosted_challenges.includes(:participants).order(created_at: :desc)
    @challenge_applications = @user.challenge_applications.includes(:challenge).order(created_at: :desc)

    # 루틴 클럽 및 리포트
    @club_memberships = @user.routine_club_members.includes(:routine_club).order(created_at: :desc)
    @recent_reports = @user.routine_club_reports.order(start_date: :desc).limit(5)

    # 개인 루틴
    @personal_routines = @user.personal_routines.order(created_at: :desc)

    # 뱃지
    @user_badges = @user.user_badges.includes(:badge).order(granted_at: :desc)
    @recent_badges = @user_badges.limit(4)

    # 리뷰
    @reviews = @user.reviews.includes(:challenge).order(created_at: :desc)

    # 루파 활동
    @rufa_activities = @user.rufa_activities.order(created_at: :desc).limit(10)

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

    # 대시보드 요약
    @active_participations = @participations.select { |p| p.challenge.status_active? }
    @active_clubs = @club_memberships.select { |m| m.routine_club.status_active? }

    # 성장 투자 통계 (실제 기능 대신 기록용)
    @growth_stats = {
      total_invested: @participations.sum { |p| p.challenge.total_payment_amount },
      total_refunded: @user.total_refunded,
      expected_refund: @active_participations.sum { |p| p.challenge.amount || 0 }
    }
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
      :nickname,
      :bio,
      :saved_bank_name,
      :saved_account_number,
      :saved_account_holder,
      sns_links: [ :instagram, :threads, :blog, :youtube, :twitter ]
    )
  end
end
