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
    @tab = params[:tab] || "info"

    # 인증 로그 (참가자 또는 호스트인 경우)
    if @is_joined || @is_host
      @verification_logs = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(50)
      @today_verified = @participant&.verification_logs&.today&.exists?
    end

    # 호스트인 경우 추가 정보
    if @is_host
      @participants = @challenge.participants.includes(:user).order(created_at: :desc)
      @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user)
    end
  end

  def new
    @challenge = Challenge.new
    @challenge.mode = params[:mode] == "offline" ? :offline : :online
    @challenge.build_meeting_info if @challenge.offline?
  end

  def create
    @challenge = Challenge.new(challenge_params)
    @challenge.host = current_user

    if @challenge.save
      redirect_to @challenge, notice: "#{@challenge.offline? ? '모임' : '챌린지'}가 성공적으로 개설되었습니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def join
    return redirect_to @challenge, alert: "이미 참여 중입니다." if current_user.participations.exists?(challenge: @challenge)

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
      :title, :summary, :description, :purpose, :category,
      :start_date, :end_date, :mode, :verification_type, :cost_type,
      :amount, :max_participants, :failure_tolerance,
      :mission_frequency, :mission_is_late_detection_enabled,
      :mission_allow_exceptions, :mission_is_consecutive,
      days: [],
      meeting_info_attributes: [ :place_name, :address, :meeting_time, :description, :max_attendees ]
    )
  end
end
