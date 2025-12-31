class ChallengeParticipantsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :require_host
  before_action :set_participant, only: [ :update, :destroy ]

  def index
    @participants = @challenge.participants.includes(:user, :verification_logs).order(created_at: :desc)
  end

  def update
    if @participant.update(participant_params)
      redirect_to challenge_participants_path(@challenge), notice: "참가자 정보가 수정되었습니다."
    else
      redirect_to challenge_participants_path(@challenge), alert: "수정에 실패했습니다."
    end
  end

  def destroy
    if @participant.update(status: :failed, refund_amount: 0)
      @challenge.decrement!(:current_participants)
      redirect_to challenge_participants_path(@challenge), notice: "참가자를 강제 퇴장(탈락) 처리했습니다."
    else
      redirect_to challenge_participants_path(@challenge), alert: "탈락 처리에 실패했습니다."
    end
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
  end

  def set_participant
    @participant = @challenge.participants.find(params[:id])
  end

  def require_host
    unless @challenge.host_id == current_user.id
      redirect_to @challenge, alert: "호스트만 접근할 수 있습니다."
    end
  end

  def participant_params
    params.require(:participant).permit(:status)
  end
end
