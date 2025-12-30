class VerificationLogsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :set_participant, only: [ :create ]
  before_action :set_verification_log, only: [ :approve, :reject ]
  before_action :require_host, only: [ :approve, :reject ]

  def create
    return redirect_to @challenge, alert: "이 챌린지에 참여하고 있지 않습니다." unless @participant

    # 탈락 여부 확인
    if @participant.failed?
      return redirect_to @challenge, alert: "죄송합니다. 최대 실패 횟수를 초과하여 더 이상 인증에 참여하실 수 없습니다."
    end

    # 오늘 이미 인증했는지 확인
    if @participant.verification_logs.today.exists?
      return redirect_to @challenge, alert: "오늘 이미 인증을 완료했습니다."
    end

    @verification_log = @participant.verification_logs.build(verification_log_params)
    @verification_log.challenge = @challenge
    @verification_log.verification_type = @challenge.verification_type

    if @verification_log.save
      # 호스트 승인이 필요없는 경우 자동 승인
      unless @challenge.mission_requires_host_approval
        @verification_log.update(status: :approved)
      end
      redirect_to @challenge, notice: "인증이 완료되었습니다!"
    else
      redirect_to @challenge, alert: "인증에 실패했습니다: #{@verification_log.errors.full_messages.join(', ')}"
    end
  end

  def approve
    if @verification_log.update(status: :approved)
      @verification_log.participant.update_streak!
      redirect_to_origin("인증을 승인했습니다.")
    else
      redirect_to_origin("승인에 실패했습니다.", :alert)
    end
  end

  def reject
    if @verification_log.update(status: :rejected, reject_reason: params[:reject_reason])
      @verification_log.participant.check_status!
      redirect_to_origin("인증을 거절했습니다.")
    else
      redirect_to_origin("거절에 실패했습니다.", :alert)
    end
  end

  private

  def redirect_to_origin(notice, type = :notice)
    if request.referer&.include?("hosted_challenges")
      redirect_to hosted_challenge_path(@challenge, tab: "dashboard"), type => notice
    else
      redirect_to challenge_path(@challenge, tab: "verifications"), type => notice
    end
  end

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_participant
    @participant = current_user.participations.find_by(challenge: @challenge)
  end

  def set_verification_log
    @verification_log = @challenge.verification_logs.find(params[:id])
  end

  def require_host
    unless @challenge.host_id == current_user.id
      redirect_to @challenge, alert: "호스트만 접근할 수 있습니다."
    end
  end

  def verification_log_params
    params.require(:verification_log).permit(:value, :image_url)
  end
end
