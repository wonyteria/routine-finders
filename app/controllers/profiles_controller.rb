class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @participations = @user.participations.includes(:challenge)
    @hosted_challenges = @user.hosted_challenges.includes(:participants)

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
end
