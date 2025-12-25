class HostedChallengesController < ApplicationController
  before_action :require_login

  def index
    @hosted_challenges = current_user.hosted_challenges
      .includes(:participants)
      .order(created_at: :desc)

    # 대기 중인 인증 건수를 미리 계산 (N+1 방지)
    @pending_counts = VerificationLog
      .where(challenge_id: @hosted_challenges.pluck(:id), status: :pending)
      .group(:challenge_id)
      .count
  end

  def show
    @challenge = current_user.hosted_challenges.find(params[:id])
    @participants = @challenge.participants.includes(:user, :verification_logs).order(created_at: :desc)
    @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user).order(created_at: :desc)
    @recent_verifications = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(20)

    # 통계
    @stats = {
      total_participants: @challenge.current_participants,
      active_today: @challenge.participants.where(today_verified: true).count,
      avg_completion_rate: @challenge.participants.average(:completion_rate)&.round(1) || 0,
      pending_count: @pending_verifications.count
    }
  end
end
