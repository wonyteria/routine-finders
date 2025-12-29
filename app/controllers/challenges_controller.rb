class ChallengesController < ApplicationController
  before_action :set_challenge, only: [ :show, :join, :leave ]
  before_action :require_login, only: [ :new, :create, :join, :leave ]

  def index
    @challenges = Challenge.online_challenges.order(created_at: :desc)
    @title = "챌린지 탐색"
    @description = "온라인으로 함께 습관을 만드는 챌린지"
  end

  def show
    @is_joined = current_user&.participations&.exists?(challenge: @challenge)
    @participant = current_user&.participations&.find_by(challenge: @challenge)
    @is_host = current_user&.id == @challenge.host_id
    @tab = params[:tab] || "intro"

    # Common data for all tabs
    @participants_count = @challenge.current_participants
    @reviews = Review.where(challenge_id: [ @challenge.id, @challenge.original_challenge_id ].compact)
                     .recent.includes(:user)

    # Specific tab data
    case @tab
    when "participants"
      @participants = @challenge.participants.includes(:user).order(created_at: :desc)
    when "verifications"
      if @is_joined || @is_host
        @verification_logs = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(50)
        @today_verified = @participant&.verification_logs&.today&.exists?
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
    @challenge = Challenge.new(challenge_params)
    @challenge.host = current_user

    if @challenge.save
      if @challenge.save_account_to_profile == "1"
        current_user.update(
          saved_bank_name: @challenge.host_bank,
          saved_account_number: @challenge.host_account,
          saved_account_holder: @challenge.host_account_holder
        )
      end
      redirect_to @challenge, notice: "#{@challenge.offline? ? '모임' : '챌린지'}가 성공적으로 개설되었습니다!"
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

    participant = @challenge.participants.build(
      user: current_user,
      paid_amount: @challenge.amount,
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

    if participant&.destroy
      @challenge.decrement!(:current_participants)
      redirect_to challenges_path, notice: "챌린지에서 탈퇴했습니다."
    else
      redirect_to @challenge, alert: "탈퇴에 실패했습니다."
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
      :amount, :max_participants, :failure_tolerance, :penalty_per_failure,
      :mission_frequency, :mission_is_late_detection_enabled,
      :mission_allow_exceptions, :mission_is_consecutive, :mission_requires_host_approval,
      :verification_start_time, :verification_end_time, :re_verification_allowed,
      :is_private, :admission_type, :host_bank, :host_account, :host_account_holder,
      :v_photo, :v_simple, :v_metric, :v_url, :thumbnail_image, :save_account_to_profile,
      days: [],
      meeting_info_attributes: [ :place_name, :address, :meeting_time, :description, :max_attendees ]
    )
  end
end
