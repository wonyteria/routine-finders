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
      unverified_today: @challenge.participants.where(today_verified: [ false, nil ]).count,
      avg_completion_rate: @challenge.participants.average(:completion_rate)&.round(1) || 0,
      streak_keepers: @challenge.participants.where("current_streak > 0").count,
      dropped_out: @challenge.participants.failed.count,
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

  def update
    @challenge = current_user.hosted_challenges.find(params[:id])
    if @challenge.update(challenge_params)
      redirect_to hosted_challenge_path(@challenge, tab: params[:tab]), notice: "설정이 저장되었습니다."
    else
      redirect_to hosted_challenge_path(@challenge, tab: params[:tab]), alert: "저장에 실패했습니다."
    end
  end

  private

  def challenge_params
    params.require(:challenge).permit(
      :title, :summary, :description, :custom_host_bio,
      :start_date, :end_date,
      :cost_type, :amount, :max_participants, :failure_tolerance, :penalty_per_failure,
      :full_refund_threshold, :bonus_threshold,
      :verification_start_time, :verification_end_time, :re_verification_allowed,
      :mission_requires_host_approval,
      :host_bank, :host_account, :host_account_holder,
      :certification_goal, :daily_goals, :reward_policy,
      :active_rate_threshold,
      :sluggish_rate_threshold,
      :non_participating_failures_threshold,
      :thumbnail_image,
      days: []
    )
  end

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
    @participants = @challenge.participants.includes(:user, :verification_logs)

    # 필터
    if params[:status].present?
      @participants = @participants.where(status: params[:status])
    end

    # 정렬
    case params[:sort]
    when "achievement_low"
      @participants = @participants.order(completion_rate: :asc)
    when "missed_recent"
      @participants = @participants.order(consecutive_failures: :desc)
    else
      @participants = @participants.order(created_at: :desc)
    end
  end
end
