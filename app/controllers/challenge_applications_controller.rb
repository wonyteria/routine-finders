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

    if params[:source] == "prototype"
      render layout: "prototype"
    end
  end

  # GET /challenges/:challenge_id/applications/new
  def new
    # Check if user is the host
    if current_user.id == @challenge.host_id
      path = params[:source] == "prototype" ? challenge_path(@challenge, source: "prototype") : @challenge
      return redirect_to path, alert: "호스트는 신청할 수 없습니다."
    end

    # Check if already a participant
    if current_user.participations.exists?(challenge: @challenge)
      path = params[:source] == "prototype" ? challenge_path(@challenge, source: "prototype") : @challenge
      return redirect_to path, alert: "이미 참여 중인 챌린지입니다."
    end

    # Check for existing pending/approved application
    existing_application = @challenge.challenge_applications.find_by(user: current_user)
    if existing_application
      if existing_application.pending?
        path = params[:source] == "prototype" ? challenge_path(@challenge, source: "prototype") : @challenge
        return redirect_to path, alert: "이미 신청 후 승인 대기 중입니다."
      elsif existing_application.approved?
        path = params[:source] == "prototype" ? challenge_path(@challenge, source: "prototype") : @challenge
        return redirect_to path, alert: "이미 승인된 신청입니다."
      elsif existing_application.rejected?
        @rejected_application = existing_application
      end
    end

    @application = @challenge.challenge_applications.build

    if params[:source] == "prototype"
      render layout: "prototype"
    end
  end

  # POST /challenges/:challenge_id/applications
  def create
    # First, handle re-application by cleaning up previous rejected application
    @challenge.challenge_applications.where(user: current_user, status: :rejected).destroy_all

    @application = @challenge.challenge_applications.build(application_params)
    @application.user = current_user

    if @application.save
      redirect_target = if params[:source] == "prototype" || (params[:challenge_application] && params[:challenge_application][:source] == "prototype")
        challenge_path(@challenge, source: "prototype")
      else
        @challenge
      end

      begin
        if !@challenge.requires_approval?
          # [Case 1] 즉시 참여 (No Approval Required)
          ActiveRecord::Base.transaction do
            @application.approve!

            # Create participant record
            @challenge.participants.create!(
              user: current_user,
              paid_amount: @challenge.total_payment_amount,
              joined_at: Time.current,
              contact_info: @application.contact_info,
              threads_nickname: @application.threads_nickname,
              refund_bank_name: @application.refund_bank_name,
              refund_account_number: @application.refund_account_number,
              refund_account_name: @application.refund_account_name
            )

            @challenge.increment!(:current_participants)
          end

          redirect_to redirect_target, notice: "챌린지 참여가 완료되었습니다! 입금 확인 후 활동을 시작할 수 있습니다."
        else
          # [Case 2] 승인 필요 (Approval Required)
          # 알림 발송 실패가 신청 자체를 막지 않도록 처리
          begin
            create_notification_for_host
          rescue => e
            Rails.logger.error "Failed to create host notification for application #{@application.id}: #{e.message}"
          end

          redirect_to redirect_target, notice: "신청이 완료되었습니다. 호스트의 승인을 기다려주세요."
        end

      rescue => e
        # 즉시 참여 과정(트랜잭션 내부)에서 실패한 경우 신청서 삭제 후 에러 반환
        @application.destroy
        Rails.logger.error "Application processing failed: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
        redirect_to redirect_target, alert: "참여 처리 중 오류가 발생했습니다: #{e.message}"
      end
    else
      msg = @application.errors.full_messages.to_sentence
      Rails.logger.error "Application Save Failed: #{msg}"

      redirect_target = if params[:source] == "prototype" || (params[:challenge_application] && params[:challenge_application][:source] == "prototype")
        challenge_path(@challenge, source: "prototype")
      else
        @challenge
      end

      redirect_to redirect_target, alert: "신청서 저장에 실패했습니다: #{msg}"
    end
  end

  # POST /challenges/:challenge_id/applications/:id/approve
  def approve
    message = params[:message]
    ActiveRecord::Base.transaction do
      @application.approve!

      # Create participant record
      @challenge.participants.create!(
        user: @application.user,
        paid_amount: @challenge.total_payment_amount,
        joined_at: Time.current,
        contact_info: @application.contact_info,
        threads_nickname: @application.threads_nickname,
        refund_bank_name: @application.refund_bank_name,
        refund_account_number: @application.refund_account_number,
        refund_account_name: @application.refund_account_name
      )

      @challenge.increment!(:current_participants)

      # Notify applicant about approval
      create_notification_for_applicant(:approval, message)
    end

    redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: "applications", source: "prototype") : challenge_applications_path(@challenge)
    redirect_to redirect_path, notice: "신청을 승인했습니다."
  rescue ActiveRecord::RecordInvalid => e
    redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: "applications", source: "prototype") : challenge_applications_path(@challenge)
    redirect_to redirect_path, alert: "승인 처리 중 오류가 발생했습니다: #{e.message}"
  end

  # POST /challenges/:challenge_id/applications/:id/reject
  def reject
    message = params[:message] || params[:reject_reason]

    @application.reject!(message)

    # Notify applicant about rejection
    create_notification_for_applicant(:rejection, message)

    redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: "applications", source: "prototype") : challenge_applications_path(@challenge)
    redirect_to redirect_path, notice: "신청을 거절했습니다."
  end

  private

  def set_challenge
    @challenge = Challenge.find(params[:challenge_id])
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
    params.require(:challenge_application).permit(:message, :depositor_name, :contact_info, :threads_nickname, :source, :refund_bank_name, :refund_account_number, :refund_account_name, application_answers: {})
  end

  def create_notification_for_host
    Notification.create!(
      user: @challenge.host,
      notification_type: :application,
      title: @challenge.offline? ? "새로운 모임 참가 신청" : "새로운 챌린지 신청",
      message: "#{@challenge.offline? ? "#{current_user.nickname}님이 #{@challenge.title} 모임에 참가 신청했습니다." : "#{current_user.nickname}님이 #{@challenge.title} 챌린지에 신청했습니다."}",
      link: "/challenges/#{@challenge.id}?tab=applications&source=prototype"

    )
  end

  def create_notification_for_applicant(type, message = nil)
    case type
    when :approval
      Notification.create!(
        user: @application.user,
        notification_type: :approval,
        title: "챌린지 신청 승인",
        message: "'#{@challenge.title}' 챌린지 신청이 승인되었습니다!#{message.present? ? "\n호스트 메시지: #{message}" : ""}",
        link: "/challenges/#{@challenge.id}?source=prototype"

      )
    when :rejection
      Notification.create!(
        user: @application.user,
        notification_type: :rejection,
        title: "챌린지 신청 거절",
        message: "'#{@challenge.title}' 챌린지 신청이 거절되었습니다.#{message.present? ? " 사유: #{message}" : ""}",
        link: "/challenges/#{@challenge.id}?source=prototype"

      )
    end
  end
end
