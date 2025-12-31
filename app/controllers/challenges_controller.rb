class ChallengesController < ApplicationController
  before_action :set_challenge, only: [ :show, :join, :leave ]
  before_action :require_login, only: [ :new, :create, :join, :leave ]

  def index
    # 검색 모드인지 확인 (키워드, 카테고리, 상태 필터가 하나라도 있으면 검색 모드)
    @is_search_mode = params[:keyword].present? || params[:category].present? || params[:status].present?

    if @is_search_mode
      # === 검색 모드 로직 ===
      @challenges = Challenge.online_challenges.recruiting # 기본적으로 모집중인 것만 검색? 아니면 전체? -> 요구사항에 따라 전체에서 필터링
      # 검색 시엔 상태 필터가 없으면 '모집중/진행중' 위주로 보여주는게 좋지만, 일단 전체 베이스에서 필터링
      @challenges = Challenge.online_challenges 

      # 키워드 검색
      if params[:keyword].present?
        @challenges = @challenges.where("title LIKE ?", "%#{params[:keyword]}%")
      end

      # 카테고리 필터
      if params[:category].present?
        @challenges = @challenges.where(category: params[:category])
      end

      # 상태 필터
      if params[:status].present?
        case params[:status]
        when 'recruiting'
          # 모집중 (모집 기간 내)
          @challenges = @challenges.where("recruitment_start_date <= ? AND recruitment_end_date >= ?", Date.current, Date.current)
        when 'active'
          # 진행중 (시작 ~ 종료)
          @challenges = @challenges.active
        when 'ended'
          # 종료됨
          @challenges = @challenges.ended
        end
      else
        # 상태 필터가 없을 땐 기본적으로 모집중 + 진행중 + 예정 표시 (종료된 건 뒤로 밀거나 제외할 수도 있음)
        # 여기서는 단순 최신순
      end
      
      @challenges = @challenges.order(created_at: :desc)
      
    else
      # === 랜딩 페이지(기본) 모드 로직 ===
      # 1. 추천 챌린지 (Official or Random Pick)
      @featured_challenges = Challenge.online_challenges.official.limit(4)
      if @featured_challenges.empty?
        # Official이 없으면 썸네일이 있는 것 중 랜덤 4개 혹은 최신 4개
        @featured_challenges = Challenge.online_challenges.recruiting.where.not(thumbnail_image: nil).limit(4)
        if @featured_challenges.empty?
           @featured_challenges = Challenge.online_challenges.recruiting.limit(4)
        end
      end

      # 2. 핫한 챌린지 (참여자 많은 순 + 모집중)
      @hot_challenges = Challenge.online_challenges.recruiting.order(current_participants: :desc).limit(6)

      # 3. 그 외 챌린지 (전체 모집중인 챌린지 최신순)
      # 상단에 노출된 것과 중복될 수 있으나, 탐색 영역에는 전체가 나오는 게 자연스러움
      @challenges = Challenge.online_challenges.recruiting.order(created_at: :desc).limit(12)
    end

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
      # Dashboard specific data
      @remaining_days = (@challenge.end_date - Date.current).to_i
      @d_day = @remaining_days.positive? ? "D-#{@remaining_days}" : (@remaining_days.zero? ? "D-Day" : "종료")
      @today_verified = @participant.verification_logs.today.exists?
      @recent_verifications = @challenge.verification_logs.includes(participant: :user).recent.limit(5)
      @announcements = @challenge.announcements.order(is_pinned: :desc, created_at: :desc).limit(3)

      # Participants with today's verification status
      @participants_with_status = @challenge.participants.includes(:user).map do |p|
        {
          id: p.id,
          nickname: p.nickname,
          profile_image: p.profile_image,
          is_me: p.user_id == current_user.id,
          verified_today: p.verification_logs.today.exists?,
          completion_rate: p.completion_rate
        }
      end.sort_by { |p| [ p[:is_me] ? 0 : 1, p[:verified_today] ? 0 : 1 ] }

      # Rankings (top 5)
      @rankings = @challenge.participants.includes(:user).order(completion_rate: :desc, current_streak: :desc).limit(5)

      # Pending Verifications for Host
      @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user) if @is_host

      # Refund Eligibility (3 days before end date)
      @can_apply_refund = @challenge.cost_type_deposit? && @remaining_days <= 3 && @remaining_days >= 0

      # Common dashboard stats
      @today_verified_count = @challenge.verification_logs.today.count

      # User's existing review (for edit limit info)
      @user_review = @challenge.reviews.find_by(user: current_user)

      # Grass Data (Daily verification status map)
      all_logs = @participant.verification_logs.approved.pluck(:created_at).map(&:to_date)
      @daily_status_map = {}
      (@challenge.start_date..@challenge.end_date).each do |date|
        @daily_status_map[date] = all_logs.include?(date)
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
      @this_week_count = verifications_this_week
    end

    # Specific tab data
    case @tab
    when "participants"
      @participants = @challenge.participants.includes(:user).order(created_at: :desc)
    when "announcements"
      @announcements_all = @challenge.announcements.order(created_at: :desc)
    when "verifications"
      if @is_joined || @is_host
        @verification_logs = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(50)
        @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user) if @is_host
      end
    end

    # Can write review? (Joined for 7+ days and not reviewed yet)
    @can_write_review = @is_joined &&
                        @participant.joined_at <= 7.days.ago &&
                        !@challenge.reviews.exists?(user: current_user)
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
    params_hash = challenge_params

    # Convert full_refund_threshold from percentage (0-100) to decimal (0-1)
    if params_hash[:full_refund_threshold].present?
      params_hash[:full_refund_threshold] = params_hash[:full_refund_threshold].to_f / 100.0
    end

    @challenge = Challenge.new(params_hash)
    @challenge.host = current_user

    if @challenge.save
      if @challenge.save_account_to_profile == "1"
        current_user.update(
          saved_bank_name: @challenge.host_bank,
          saved_account_number: @challenge.host_account,
          saved_account_holder: @challenge.host_account_holder
        )
      end
      redirect_to hosted_challenge_path(@challenge), notice: "#{@challenge.offline? ? '모임' : '챌린지'}가 성공적으로 개설되었습니다!"
    else
      @saved_account = current_user.saved_account
      @has_saved_account = current_user.has_saved_account?
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

    participant = @challenge.participants.build(
      user: current_user,
      paid_amount: @challenge.total_payment_amount,
      joined_at: Time.current
    )

    if participant.save
      @challenge.increment!(:current_participants)
      redirect_to @challenge, notice: "챌린지에 참여했습니다!"
    else
      redirect_to @challenge, alert: "참여에 실패했습니다."
    end
  end

  def leave
    participant = current_user.participations.find_by(challenge: @challenge)
    return redirect_to @challenge, alert: "참여 정보가 없습니다." unless participant

    if participant.update(status: :abandoned, refund_amount: 0)
      @challenge.decrement!(:current_participants)
      redirect_to challenges_path, notice: "챌린지를 중도 포기했습니다."
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
      :is_private, :admission_type, :host_bank, :host_account, :host_account_holder,
      :v_photo, :v_simple, :v_metric, :v_url, :thumbnail_image, :save_account_to_profile,
      :certification_goal, :daily_goals, :reward_policy,
      :full_refund_threshold, :refund_date, :recruitment_start_date, :recruitment_end_date,
      days: [],
      meeting_info_attributes: [ :place_name, :address, :meeting_time, :description, :max_attendees ]
    )
  end
end
