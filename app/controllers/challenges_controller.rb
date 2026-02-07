class ChallengesController < ApplicationController
  before_action :set_challenge, only: [ :show, :join, :leave ]
  before_action :require_login, only: [ :new, :create, :join, :leave ]
  before_action :require_can_create_challenge, only: [ :new, :create ]
  skip_before_action :require_login, only: [ :index, :show ]

  def index
    # 챌린지 탐색을 기본으로 설정 (사용자 요청에 따라 랜딩 데이터 로딩 제거)
    search_challenges

    # Get user's joined challenge IDs for displaying badges
    @joined_challenge_ids = current_user&.participations&.pluck(:challenge_id) || []

    @title = "챌린지 탐색"
    @description = "온라인으로 함께 습관을 만드는 챌린지"
  end

  def show
    @is_joined = current_user&.participations&.exists?(challenge: @challenge)
    @participant = current_user&.participations&.find_by(challenge: @challenge)
    @is_host = current_user&.id == @challenge.host_id
    @tab = params[:tab] || (@is_joined ? "records" : "intro")

    # Common data
    @participants_count = @challenge.current_participants
    @reviews = Review.where(challenge_id: [ @challenge.id, @challenge.original_challenge_id ].compact)
                     .recent.includes(:user)

    if @is_joined
      # Dashboard specific data (Safe handling for nil dates)
      if @challenge.end_date
        @remaining_days = (@challenge.end_date - Date.current).to_i
        @d_day = @remaining_days.positive? ? "D-#{@remaining_days}" : (@remaining_days.zero? ? "D-Day" : "종료")
      else
        @remaining_days = 0
        @d_day = "설정 전"
      end
      @today_verified = @participant.verification_logs.today.exists?
      @recent_verifications = @challenge.verification_logs.includes(participant: :user).recent.limit(5)
      @announcements = @challenge.announcements.order(is_pinned: :desc, created_at: :desc).limit(3)

      # Participants with today's verification status (Safe handling)
      @participants_with_status = @challenge.participants.includes(:user).map do |p|
        next nil unless p.user
        {
          id: p.id,
          nickname: p.nickname || "익명",
          profile_image: p.profile_image,
          is_me: p.user_id == current_user&.id,
          verified_today: p.verification_logs.today.exists?,
          completion_rate: p.completion_rate || 0
        }
      end.compact.sort_by { |p| [ p[:is_me] ? 0 : 1, p[:verified_today] ? 0 : 1 ] }

      # Rankings (top 5)
      @rankings = @challenge.participants.includes(:user).order(completion_rate: :desc, current_streak: :desc).limit(5)

    # Pending Verifications for Host
    @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user) if @is_host

    # Management Data for Host (Gathering)
    if @is_host
      @applications = @challenge.challenge_applications.includes(:user).recent
      @pending_applications = @applications.pending
      @processed_applications = @applications.where.not(status: :pending)
    end

      # Refund Eligibility (3 3days before end date)
      @can_apply_refund = @challenge.cost_type_deposit? && @remaining_days <= 3 && @remaining_days >= 0

      # Common dashboard stats
      @today_verified_count = @challenge.verification_logs.today.count

      # User's existing review (for edit limit info)
      @user_review = @challenge.reviews.find_by(user: current_user)

      # Grass Data (Safe date range)
      all_logs = @participant.verification_logs.approved.pluck(:created_at).map(&:to_date)
      @daily_status_map = {}
      if @challenge.start_date && @challenge.end_date
        (@challenge.start_date..@challenge.end_date).each do |date|
          @daily_status_map[date] = all_logs.include?(date)
        end
      end

      # 식물 성장 단계 (루파 열매 컨셉)
      @growth_stages = [
        { threshold: 100, name: "최고의 결실, 루파 열매 달성!", stage: 5 },
        { threshold: 80, name: "드디어 꽃이 피어났어요!", stage: 4 },
        { threshold: 60, name: "성취의 꽃이 필 준비 완료!", stage: 3 },
        { threshold: 40, name: "푸른 성장이 눈에 띄어요!", stage: 2 },
        { threshold: 20, name: "무럭무럭 자라나고 있어요!", stage: 1 },
        { threshold: 0, name: "성공의 씨앗을 심었어요!", stage: 0 }
      ]
      @current_growth_stage = @growth_stages.find { |s| @participant.completion_rate >= s[:threshold] }

      # Detailed Stats for Growth Dashboard
      @completed_days = @participant.verification_logs.approved.count
      @achieved_weeks = @participant.verification_logs.approved.pluck(:created_at).map { |d| d.to_date.strftime("%W") }.uniq.count

      # This week's progress
      start_of_week = Date.current.beginning_of_week
      verifications_this_week = @participant.verification_logs.approved.where("created_at >= ?", start_of_week).count
      @this_week_completion_rate = (verifications_this_week / 7.0 * 100).to_i
      @this_week_count = verifications_this_week || 0
    end

    # All data needed for the new vertical-scroll guest show
    @participants = @challenge.participants.includes(:user).order(created_at: :desc)
    @announcements_all = @challenge.announcements.order(created_at: :desc)

    # Specific tab data (for non-prototype web view)
    case @tab
    when "verifications"
      if @is_joined || @is_host
        @verification_logs = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(50)
        @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user) if @is_host
      end
    end

    # Can write review? Improved for Offline Gatherings
    if @is_joined && !@challenge.reviews.exists?(user: current_user)
      if @challenge.offline?
        # 오프라인 모임은 모임 당일 혹은 그 이후부터 작성 가능
        @can_write_review = Date.current >= @challenge.start_date
      else
        # 온라인 챌린지는 기존처럼 7일 경과 후 작성 가능
        @can_write_review = @participant.joined_at <= 7.days.ago
      end
    else
      @can_write_review = false
    end

    if params[:source] == "prototype"
      render layout: "prototype"
    end
  end

  def clone
    original = Challenge.find(params[:id])
    @challenge = original.dup
    @challenge.title = "[복사] #{original.title}"
    @challenge.start_date = Date.current + 1.day
    @challenge.end_date = Date.current + (original.end_date - original.start_date).to_i.days + 1.day
    @challenge.recruitment_start_date = Date.current
    @challenge.recruitment_end_date = @challenge.start_date - 1.day
    @challenge.current_participants = 0
    @challenge.host = current_user
    @challenge.original_challenge = original

    # Optional: copy meeting info if present
    if original.offline? && original.meeting_info
      @challenge.build_meeting_info(original.meeting_info.attributes.except("id", "challenge_id", "created_at", "updated_at"))
    end

    render :new
  end

  def new
    @challenge = Challenge.new
    @challenge.mode = params[:mode] == "offline" ? :offline : :online
    @challenge.build_meeting_info if @challenge.offline?
    @saved_account = current_user.saved_account
    @has_saved_account = current_user.has_saved_account?
  end

  def create
    [ :days, :daily_goals, :reward_policy, :certification_goal ].each do |attr|
    if params[:challenge] && params[:challenge][attr].is_a?(String)
      begin
        params[:challenge][attr] = JSON.parse(params[:challenge][attr])
        if attr == :days && params[:challenge][attr].is_a?(Array)
          params[:challenge][attr] = params[:challenge][attr].map(&:to_s)
        end
      rescue JSON::ParserError
      end
    end
  end

  params_hash = challenge_params

    # Convert full_refund_threshold from percentage (0-100) to decimal (0-1)
    if params_hash[:full_refund_threshold].present?
      params_hash[:full_refund_threshold] = params_hash[:full_refund_threshold].to_f / 100.0
    end

    @challenge = Challenge.new(params_hash)
    @challenge.host = current_user

    # Ensure offline gatherings have consistent dates
    if @challenge.offline?
      @challenge.end_date = @challenge.start_date
      @challenge.mission_frequency = :daily
    end

    if @challenge.save
      if @challenge.save_account_to_profile == "1"
        current_user.update(
          saved_bank_name: @challenge.host_bank,
          saved_account_number: @challenge.host_account,
          saved_account_holder: @challenge.host_account_holder
        )
      end

      if params[:source] == "prototype"
        redirect_to prototype_home_path(created_challenge: true), notice: "#{@challenge.offline? ? '모임' : '챌린지'}가 성공적으로 개설되었습니다!"
      else
        redirect_to hosted_challenge_path(@challenge), notice: "#{@challenge.offline? ? '모임' : '챌린지'}가 성공적으로 개설되었습니다!"
      end
    else
      @saved_account = current_user.saved_account
      @has_saved_account = current_user.has_saved_account?
      flash.now[:alert] = "챌린지 생성 실패: #{@challenge.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def join
    return redirect_to @challenge, alert: "이미 참여 중입니다." if current_user.participations.exists?(challenge: @challenge)


    if @challenge.is_private? && params[:invitation_code] != @challenge.invitation_code
      return redirect_to @challenge, alert: "초대 코드가 올바르지 않습니다."
    end

    if @challenge.recruitment_end_date.present? && Date.current > @challenge.recruitment_end_date
      return redirect_to @challenge, alert: "모집 기간이 이미 종료된 챌린지입니다."
    end

    # Priority Access Check
    if @challenge.priority_access_for_members?
      is_premium = current_user.admin? || current_user.routine_club_members.active.any?
      unless is_premium
        return redirect_to @challenge, alert: "현재는 루파 클럽 멤버 전용 우선 신청 기간입니다. (오픈까지 약 1시간 미만 남음)"
      end
    end

    begin
      ActiveRecord::Base.transaction do
        @challenge.participants.create!(
          user: current_user,
          paid_amount: @challenge.total_payment_amount,
          joined_at: Time.current
        )
        @challenge.increment!(:current_participants)
      end
      path = params[:source] == "prototype" ? challenge_path(@challenge, source: "prototype") : @challenge
      redirect_to path, notice: "챌린지에 참여했습니다!"
    rescue => e
      redirect_to @challenge, alert: "참여 처리 중 오류가 발생했습니다: #{e.message}"
    end
  end

  def leave
    participant = current_user.participations.find_by(challenge: @challenge)
    return redirect_to @challenge, alert: "참여 정보가 없습니다." unless participant

    if participant.update(status: :abandoned, refund_amount: 0)
      path = params[:source] == "prototype" ? prototype_explore_path : challenges_path
      redirect_to path, notice: "챌린지를 중도 포기했습니다."
    else
      redirect_to @challenge, alert: "탈퇴 처리에 실패했습니다."
    end
  end

  def apply_refund
    @participant = current_user.participations.find_by(challenge: @challenge)
    return redirect_to @challenge, alert: "참여 정보가 없습니다." unless @participant

    is_ended_or_near_end = @challenge.status_ended? || ((@challenge.end_date - Date.current).to_i <= 3)
    unless @challenge.cost_type_deposit? && is_ended_or_near_end
      return redirect_to @challenge, alert: "환급 신청 기간이 아닙니다."
    end

    if @participant.update(
      refund_bank_name: params[:refund_bank_name],
      refund_account_number: params[:refund_account_number],
      refund_account_name: params[:refund_account_name],
      refund_status: :refund_applied,
      refund_applied_at: Time.current
    )
      redirect_to @challenge, notice: "환급 신청이 완료되었습니다. 호스트가 확인 후 환급해 드릴 예정입니다."
    else
      redirect_to @challenge, alert: "환급 신청에 실패했습니다."
    end
  end

  private

  def search_challenges
    @challenges = Challenge.online_challenges.public_challenges
    filter_by_keyword
    filter_by_category
    filter_by_status
    @challenges = @challenges.order(created_at: :desc)
  end

  def filter_by_keyword
    return if params[:keyword].blank?

    @challenges = @challenges.where("title LIKE ? OR summary LIKE ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%")
  end

  def filter_by_category
    return if params[:category].blank?

    @challenges = @challenges.where(category: params[:category])
  end

  def filter_by_status
    if params[:status].present?
      case params[:status]
      when "recruiting"
        @challenges = @challenges.recruiting
      when "active"
        @challenges = @challenges.active
      when "ended"
        @challenges = @challenges.status_ended
      end
    end
  end

  def set_challenge
    @challenge = Challenge.find(params[:id])
  end

  def challenge_params
    params.require(:challenge).permit(
      :title, :summary, :description, :purpose, :category, :thumbnail, :custom_host_bio,
      :start_date, :end_date, :mode, :verification_type, :cost_type,
      :amount, :participation_fee, :max_participants, :failure_tolerance, :penalty_per_failure,
      :mission_frequency, :mission_is_late_detection_enabled,
      :mission_allow_exceptions, :mission_is_consecutive, :mission_requires_host_approval,
      :verification_start_time, :verification_end_time, :re_verification_allowed,
      :is_private, :invitation_code, :admission_type, :host_bank, :host_account, :host_account_holder,
      :v_photo, :v_simple, :v_metric, :v_url, :thumbnail_image, :save_account_to_profile,
      :certification_goal, :daily_goals, :reward_policy,
      :full_refund_threshold, :refund_date, :recruitment_start_date, :recruitment_end_date,
      :chat_link, :host_phone, :application_question, :requires_application_message, :preparation_items, :refund_policy,
      days: [],
      meeting_info_attributes: [ :place_name, :address, :meeting_time, :description, :max_attendees ]
    )
  end
end
