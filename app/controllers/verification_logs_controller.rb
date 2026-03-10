class VerificationLogsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :set_participant, only: [ :new, :create ]
  before_action :set_verification_log, only: [ :approve, :reject ]
  before_action :require_host, only: [ :approve, :reject ]

  def new
    return redirect_to redirect_path_for_challenge, alert: "이 챌린지에 참여하고 있지 않습니다." unless @participant
    return redirect_to redirect_path_for_challenge, alert: "챌린지 진행 기간에만 인증할 수 있습니다." unless @challenge.active_period?

    @verification_log = @participant.verification_logs.build

    if params[:source] == "prototype"
      render layout: "prototype"
    end
  end

  def create
    return redirect_to redirect_path_for_challenge, alert: "이 챌린지에 참여하고 있지 않습니다." unless @participant
    return redirect_to redirect_path_for_challenge, alert: "챌린지 진행 기간에만 인증할 수 있습니다." unless @challenge.active_period?

    # 참여 중지/탈락/포기 상태 확인
    unless @participant.active?
      return redirect_to redirect_path_for_challenge, alert: "현재 활성 참여 상태가 아니므로 인증을 진행할 수 없습니다."
    end

    today_logs = @participant.verification_logs.today

  # 1. 이미 승인되거나 대기중인 인증이 있는 경우 차단
  if today_logs.where(status: [ :pending, :approved ]).exists?
    return redirect_to redirect_path_for_challenge, alert: "오늘 이미 인증을 제출하셨거나 확인 대기 중입니다."
  end

  # 2. 반려당했는데 호스트가 재인증을 미허용한 경우 차단
  if !@challenge.re_verification_allowed && today_logs.where(status: :rejected).exists?
    return redirect_to redirect_path_for_challenge, alert: "인증 기록이 반려되었으며, 안타깝게도 재인증 기회가 제공되지 않는 챌린지입니다."
  end

    @verification_log = @participant.verification_logs.build(verification_log_params)
    @verification_log.challenge = @challenge
    @verification_log.verification_type = @challenge.verification_type

    # 인증 데이터 검증
    if !valid_verification_data?(@verification_log)
      return redirect_to redirect_path_for_challenge, alert: "인증 내용을 입력해주세요."
    end

    if @verification_log.save
      # 호스트 승인이 필요없는 경우 자동 승인
      unless @challenge.mission_requires_host_approval
        @verification_log.update(status: :approved)
        # Note: update_streak! is handled via after_save callback in VerificationLog model
      end

      notice_msg = "인증이 완료되었습니다!"
      redirect_to redirect_path_for_challenge, notice: notice_msg
    else
      if params[:source] == "prototype" || (params[:verification_log] && params[:verification_log][:source] == "prototype")
        render :new, layout: "prototype", status: :unprocessable_entity
      else
        redirect_to redirect_path_for_challenge, alert: "인증에 실패했습니다: #{@verification_log.errors.full_messages.join(', ')}"
      end
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
    source_params = params[:source] == "prototype" ? { source: "prototype" } : {}
    if request.referer&.include?("hosted_challenges")
      redirect_to hosted_challenge_path(@challenge, source_params.merge(tab: "dashboard")), type => notice
    else
      redirect_to challenge_path(@challenge, source_params.merge(tab: "verifications")), type => notice
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
      redirect_to redirect_path_for_challenge, alert: "호스트만 접근할 수 있습니다."
    end
  end

  def verification_log_params
    params.require(:verification_log).permit(:value, :image_url)
  end

  def valid_verification_data?(log)
    v_type = log.verification_type
    return false if v_type.blank?

    case v_type.to_s.to_sym
    when :photo
      # 사진 인증: image_url 필수
      log.image_url.present?
    when :metric, :url
      # 수치/URL 인증: value 필수
      log.value.present?
    when :simple
      # 간단 인증: value가 있거나 "completed" 같은 기본값이 있어야 함
      log.value.present?
    when :complex
      # 복합 인증: image_url 또는 value 중 하나는 있어야 함
      log.image_url.present? || log.value.present?
    else
      false
    end
  rescue => e
    Rails.logger.error "[VerificationLogsController] Validation failed: #{e.message}"
    false
  end

  def redirect_path_for_challenge
    if params[:source] == "prototype"
      challenge_path(@challenge, source: "prototype")
    else
      challenge_path(@challenge)
    end
  end
end
