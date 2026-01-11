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

    # 공통 데이터 - 최적화된 쿼리
    participants = @challenge.participants
    @stats = {
      total_participants: @challenge.current_participants,
      active_today: participants.where(today_verified: true).count,
      unverified_today: participants.where(today_verified: [ false, nil ]).count,
      avg_completion_rate: participants.average(:completion_rate)&.round(1) || 0,
      streak_keepers: participants.where("current_streak > 0").count,
      dropped_out: participants.failed.count,
      pending_verifications: @challenge.verification_logs.pending.count,
      pending_applications: @challenge.challenge_applications.pending.count,
      pending_refunds: @challenge.cost_type_deposit? ? participants.refund_applied.count : 0
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
    when "refunds"
      if @challenge.cost_type_deposit?
        load_refunds_data
      else
        redirect_to hosted_challenge_path(@challenge, tab: "dashboard"), alert: "환급 관리는 보증금 챌린지에서만 사용 가능합니다."
      end
    end
  end

  def complete_refund
    @challenge = current_user.hosted_challenges.find(params[:id])
    participant = @challenge.participants.find(params[:participant_id])

    if participant.refund_applied?
      participant.update!(refund_status: :refund_completed)
      redirect_to hosted_challenge_path(@challenge, tab: "refunds"), notice: "#{participant.user.nickname}님의 환급 처리가 완료되었습니다."
    else
      redirect_to hosted_challenge_path(@challenge, tab: "refunds"), alert: "환급 신청 상태가 아닙니다."
    end
  end

  def update
    @challenge = current_user.hosted_challenges.find(params[:id])

    params_hash = challenge_params

    # Convert percentage thresholds (0-100) to decimal (0-1)
    if params_hash[:full_refund_threshold].present?
      params_hash[:full_refund_threshold] = params_hash[:full_refund_threshold].to_f / 100.0
    end

    if params_hash[:active_rate_threshold].present?
      params_hash[:active_rate_threshold] = params_hash[:active_rate_threshold].to_f / 100.0
    end

    if params_hash[:sluggish_rate_threshold].present?
      params_hash[:sluggish_rate_threshold] = params_hash[:sluggish_rate_threshold].to_f / 100.0
    end

    success = false
    error_message = nil

    begin
      ActiveRecord::Base.transaction do
        if @challenge.update(params_hash)
          if params[:create_announcement] == "true" && params[:announcement_title].present? && params[:announcement_content].present?
            announcement = @challenge.announcements.create!(
              title: params[:announcement_title],
              content: params[:announcement_content]
            )

            # Notify all participants
            @challenge.participants.each do |participant|
              Notification.create!(
                user: participant.user,
                title: "[공지] #{@challenge.title}",
                content: announcement.title,
                link: challenge_path(@challenge, tab: "announcements"),
                notification_type: :announcement
              )
            end
          end
          success = true
        else
          error_message = @challenge.errors.full_messages.join(", ")
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      success = false
      error_message = e.record.errors.full_messages.join(", ")
    rescue => e
      success = false
      error_message = e.message
    end

    if success
      redirect_to hosted_challenge_path(@challenge, tab: params[:tab]), notice: "설정이 저장되었습니다."
    else
      redirect_to hosted_challenge_path(@challenge, tab: params[:tab]), alert: "저장에 실패했습니다#{error_message ? ': ' + error_message : ''}"
    end
  end

  def destroy
    @challenge = current_user.hosted_challenges.find(params[:id])

    if @challenge.participants.exists?
      redirect_to hosted_challenge_path(@challenge, tab: "settings"), alert: "이미 참여자가 있는 챌린지는 삭제할 수 없습니다. 대신 참가자 탭에서 개별 관리해 주세요."
    else
      @challenge.destroy
      redirect_to hosted_challenges_path, notice: "챌린지가 성공적으로 삭제되었습니다."
    end
  end

  private

  def challenge_params
    params.require(:challenge).permit(
      :title, :summary, :description, :custom_host_bio,
      :start_date, :end_date,
      :cost_type, :amount, :max_participants, :failure_tolerance, :penalty_per_failure,
      :full_refund_threshold, :refund_date,
      :verification_start_time, :verification_end_time, :re_verification_allowed,
      :mission_requires_host_approval,
      :host_bank, :host_account, :host_account_holder,
      :certification_goal, :daily_goals, :reward_policy,
      :active_rate_threshold,
      :sluggish_rate_threshold,
      :non_participating_failures_threshold,
      :thumbnail_image,
      :chat_link,
      :recruitment_start_date, :recruitment_end_date,
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

  def load_refunds_data
    @refund_applications = @challenge.participants.where.not(refund_status: :refund_none).order(refund_applied_at: :desc)
    @pending_refunds = @refund_applications.refund_applied
    @completed_refunds = @refund_applications.refund_completed
  end
end
