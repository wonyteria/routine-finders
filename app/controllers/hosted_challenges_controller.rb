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

    # 대기 중인 신청 건수
    @pending_application_counts = ChallengeApplication
      .where(challenge_id: @hosted_challenges.pluck(:id), status: :pending)
      .group(:challenge_id)
      .count
  end

  def show
    @challenge = current_user.hosted_challenges.find(params[:id])
    @tab = params[:tab] || "dashboard"

    # 공통 데이터
    @stats = {
      total_participants: @challenge.current_participants,
      active_today: @challenge.participants.where(today_verified: true).count,
      avg_completion_rate: @challenge.participants.average(:completion_rate)&.round(1) || 0,
      pending_verifications: @challenge.verification_logs.pending.count,
      pending_applications: @challenge.challenge_applications.pending.count
    }

    # 탭별 데이터 로드
    case @tab
    when "dashboard"
      load_dashboard_data
    when "applications"
      load_applications_data
    when "announcements"
      load_announcements_data
    when "reviews"
      load_reviews_data
    when "participants"
      load_participants_data
    end
  end

  private

  def load_dashboard_data
    @participants = @challenge.participants.includes(:user, :verification_logs).order(created_at: :desc)
    @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user).order(created_at: :desc)
    @recent_verifications = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(20)
  end

  def load_applications_data
    @applications = @challenge.challenge_applications.includes(:user).recent
    @pending_applications = @applications.pending
    @processed_applications = @applications.where.not(status: :pending)
  end

  def load_announcements_data
    @announcements = @challenge.announcements.recent
  end

  def load_reviews_data
    @reviews = @challenge.reviews.includes(:user).recent
  end

  def load_participants_data
    @participants = @challenge.participants.includes(:user, :verification_logs).order(created_at: :desc)
  end
end
