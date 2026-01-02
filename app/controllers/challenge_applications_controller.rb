class ChallengeApplicationsController < ApplicationController
  before_action :require_login
  before_action :set_challenge
  before_action :set_application, only: [ :approve, :reject ]
  before_action :require_host, only: [ :index, :approve, :reject ]

  # GET /challenges/:challenge_id/applications
  def index
    @applications = @challenge.challenge_applications.includes(:user).recent
    @pending_applications = @applications.pending
    @processed_applications = @applications.where.not(status: :pending)
  end

  # GET /challenges/:challenge_id/applications/new
  def new
    # Check if user is the host
    if current_user.id == @challenge.host_id
      return redirect_to @challenge, alert: "호스트는 신청할 수 없습니다."
    end

    # Check if already a participant
    if current_user.participations.exists?(challenge: @challenge)
      return redirect_to @challenge, alert: "이미 참여 중인 챌린지입니다."
    end

    # Check for existing pending/approved application
    existing_application = @challenge.challenge_applications.find_by(user: current_user)
    if existing_application
      if existing_application.pending?
        return redirect_to @challenge, alert: "이미 신청 후 승인 대기 중입니다."
      elsif existing_application.approved?
        return redirect_to @challenge, alert: "이미 승인된 신청입니다."
      elsif existing_application.rejected?
        @rejected_application = existing_application
      end
    end

    @application = @challenge.challenge_applications.build
  end

  # POST /challenges/:challenge_id/applications
  def create
    # First, handle re-application by cleaning up previous rejected application
    @challenge.challenge_applications.where(user: current_user, status: :rejected).destroy_all

    @application = @challenge.challenge_applications.build(application_params)
    @application.user = current_user

    if @application.save
      # 승인제가 아닌 경우 즉시 참여 완료
      if !@challenge.requires_approval?
        begin
          ActiveRecord::Base.transaction do
            @application.approve!

            # Create participant record
            @challenge.participants.create!(
              user: current_user,
              paid_amount: @challenge.total_payment_amount,
              joined_at: Time.current,
              contact_info: @application.contact_info
            )

            @challenge.increment!(:current_participants)
          end
          redirect_to @challenge, notice: "챌린지 참여가 완료되었습니다! 입금 확인 후 활동을 시작할 수 있습니다."
        rescue => e
          @application.destroy
          redirect_to @challenge, alert: "참여 처리 중 오류가 발생했습니다: #{e.message}"
        end
      else
        # 승인제인 경우 호스트에게 알림
        create_notification_for_host
        redirect_to @challenge, notice: "신청이 완료되었습니다. 호스트의 승인을 기다려주세요."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # POST /challenges/:challenge_id/applications/:id/approve
  def approve
    ActiveRecord::Base.transaction do
      @application.approve!

      # Create participant record
      @challenge.participants.create!(
        user: @application.user,
        paid_amount: @challenge.total_payment_amount,
        joined_at: Time.current,
        contact_info: @application.contact_info
      )

      @challenge.increment!(:current_participants)

      # Notify applicant about approval
      create_notification_for_applicant(:approval)
    end

    redirect_to challenge_applications_path(@challenge), notice: "신청을 승인했습니다."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to challenge_applications_path(@challenge), alert: "승인 처리 중 오류가 발생했습니다: #{e.message}"
  end

  # POST /challenges/:challenge_id/applications/:id/reject
  def reject
    reject_reason = params[:reject_reason]

    @application.reject!(reject_reason)

    # Notify applicant about rejection
    create_notification_for_applicant(:rejection, reject_reason)

    redirect_to challenge_applications_path(@challenge), notice: "신청을 거절했습니다."
  end

  private

  def set_challenge
    challenge_id = params[:challenge_id].to_i
    if challenge_id >= 10000
      @challenge = Challenge.generate_dummy_challenges.find { |c| c.id == challenge_id }
      raise ActiveRecord::RecordNotFound, "Couldn't find dummy Challenge with 'id'=#{params[:challenge_id]}" if @challenge.nil?
    else
      @challenge = Challenge.find(params[:challenge_id])
    end
  end

  def set_application
    @application = @challenge.challenge_applications.find(params[:id])
  end

  def require_host
    unless current_user.id == @challenge.host_id
      redirect_to @challenge, alert: "호스트만 접근할 수 있습니다."
    end
  end

  def application_params
    params.require(:challenge_application).permit(:message, :depositor_name, :contact_info)
  end

  def create_notification_for_host
    Notification.create!(
      user: @challenge.host,
      notification_type: :application,
      title: @challenge.offline? ? "새로운 모임 참가 신청" : "새로운 챌린지 신청",
      message: "#{@challenge.offline? ? current_user.nickname + '님이 ' + @challenge.title + ' 모임에 참가 신청했습니다.' : current_user.nickname + '님이 ' + @challenge.title + ' 챌린지에 신청했습니다.'}",
      data: {
        challenge_id: @challenge.id,
        application_id: @application.id,
        applicant_id: current_user.id
      }
    )
  end

  def create_notification_for_applicant(type, reason = nil)
    case type
    when :approval
      Notification.create!(
        user: @application.user,
        notification_type: :approval,
        title: "챌린지 신청 승인",
        message: "'#{@challenge.title}' 챌린지 신청이 승인되었습니다!",
        data: { challenge_id: @challenge.id }
      )
    when :rejection
      Notification.create!(
        user: @application.user,
        notification_type: :rejection,
        title: "챌린지 신청 거절",
        message: "'#{@challenge.title}' 챌린지 신청이 거절되었습니다.#{reason.present? ? " 사유: #{reason}" : ""}",
        data: { challenge_id: @challenge.id, reason: reason }
      )
    end
  end
end
