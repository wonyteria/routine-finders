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
        redirect_to hosted_challenge_path(@challenge, tab: "dashboard"), alert: "환급 관리는 보증금 챌린지에서만 사용 가능합니다." and return
      end
    end

    if params[:source] == "prototype"
      @total_days = (@challenge.end_date - @challenge.start_date).to_i + 1
      @current_day = ((Date.current - @challenge.start_date).to_i + 1).clamp(0, @total_days)
      @progress_percent = (@current_day.to_f / @total_days * 100).round
      render layout: "prototype"
    end
  end

  def complete_refund
    @challenge = current_user.hosted_challenges.find(params[:id])
    participant = @challenge.participants.find(params[:participant_id])

    redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: "refunds", source: "prototype") : hosted_challenge_path(@challenge, tab: "refunds")
    if participant.refund_applied?
      participant.update!(refund_status: :refund_completed)
      redirect_to redirect_path, notice: "#{participant.user.nickname}님의 환급 처리가 완료되었습니다."
    else
      redirect_to redirect_path, alert: "환급 신청 상태가 아닙니다."
    end
  end

  def update
    @challenge = current_user.hosted_challenges.find(params[:id])

    params_hash = challenge_params

    # Convert percentage thresholds (0-100) to decimal (0-1) for DB storage
    [ :full_refund_threshold, :bonus_threshold ].each do |attr|
      if params_hash[attr].present?
        params_hash[attr] = params_hash[attr].to_f / 100.0
      end
    end

    success = false
    error_message = nil

    begin
      ActiveRecord::Base.transaction do
        if @challenge.update(params_hash)
        # Capture changes for the confirmation modal
        saved_changes = @challenge.saved_changes.except(:updated_at)
        if saved_changes.any?
          labels = {
            "title" => "제목", "summary" => "한 줄 요약", "description" => "상세 설명",
            "category" => "카테고리", "full_refund_threshold" => "전액 환급 기준",
            "bonus_threshold" => "보너스 지급 기준", "certification_goal" => "인증 목표",
            "start_date" => "시작일", "end_date" => "종료일",
            "recruitment_start_date" => "모집 시작일", "recruitment_end_date" => "모집 마감일",
            "verification_start_time" => "인증 시작", "verification_end_time" => "인증 마감",
            "cost_type" => "비용 방식", "amount" => "금액(보증금/참가비)", "participation_fee" => "추가 참가비",
            "host_bank" => "은행", "host_account" => "계좌번호", "host_account_holder" => "예금주",
            "max_participants" => "최대 인원", "is_private" => "공개 여부", "admission_type" => "승인 방식",
            "re_verification_allowed" => "재인증 허용", "mission_requires_host_approval" => "인증 승인제",
            "chat_link" => "채팅방 링크", "custom_host_bio" => "호스트 소개", "status" => "상태",
            "place_name" => "장소명", "address" => "상세 주소", "place_url" => "상세 장소 URL"
          }
          # Compact data to prevent CookieOverflow (4KB limit)
          change_logs = saved_changes.first(12).map do |attr, vals|
            new_val = vals[1]

            # Value Transformation
            display_val = case attr
            when "cost_type"
              { "free" => "무료", "fee" => "참가비", "deposit" => "보증금" }[new_val] || new_val
            when "admission_type"
              { "first_come" => "선착순", "approval" => "승인제" }[new_val] || new_val
            when "status"
              { "upcoming" => "준비중", "active" => "진행중", "ended" => "종료", "archived" => "보관" }[new_val] || new_val
            when "is_private"
              new_val ? "비공개" : "공개"
            when "re_verification_allowed", "mission_requires_host_approval"
              new_val ? "허용" : "미허용"
            when "full_refund_threshold", "bonus_threshold"
              "#{(new_val.to_f * 100).to_i}%"
            else
              new_val.to_s.truncate(30)
            end

            { a: attr, l: labels[attr] || attr.humanize, v: display_val }
          end
          flash[:updated_changes] = change_logs.to_json
        end
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
                  link: challenge_path(@challenge, tab: "announcements", source: "prototype"),
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

    redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: params[:tab], source: "prototype") : hosted_challenge_path(@challenge, tab: params[:tab])
    if success
      redirect_to redirect_path, notice: "설정이 저장되었습니다."
    else
      redirect_to redirect_path, alert: "저장에 실패했습니다#{error_message ? ': ' + error_message : ''}"
    end
  end

  def destroy
    @challenge = current_user.hosted_challenges.find(params[:id])

    if @challenge.participants.exists?
      redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: "settings", source: "prototype") : hosted_challenge_path(@challenge, tab: "settings")
      redirect_to redirect_path, alert: "이미 참여자가 있는 챌린지는 삭제할 수 없습니다. 대신 참가자 탭에서 개별 관리해 주세요."
    else
      @challenge.destroy
      redirect_path = params[:source] == "prototype" ? hosted_challenges_path(source: "prototype") : hosted_challenges_path
      redirect_to redirect_path, notice: "챌린지가 성공적으로 삭제되었습니다."
    end
  end

  def batch_approve_verifications
    @challenge = current_user.hosted_challenges.find(params[:id])
    ids = params[:log_ids] || []
    if ids.any?
      logs = @challenge.verification_logs.where(id: ids, status: :pending)
      logs.each do |log|
        log.update(status: :approved)
        log.participant.update_streak!
      end
      notice = "#{logs.count}건의 인증을 승인했습니다."
    else
      notice = "선택된 항목이 없습니다."
    end
    redirect_to hosted_challenge_path(@challenge, source: params[:source], tab: "dashboard"), notice: notice
  end

  def batch_reject_verifications
    @challenge = current_user.hosted_challenges.find(params[:id])
    ids = params[:log_ids] || []
    reason = params[:reject_reason]
    if ids.any?
      logs = @challenge.verification_logs.where(id: ids, status: :pending)
      logs.each do |log|
        log.update(status: :rejected, reject_reason: reason)
        log.participant.check_status!
      end
      notice = "#{logs.count}건의 인증을 거절했습니다."
    else
      notice = "선택된 항목이 없습니다."
    end
    redirect_to hosted_challenge_path(@challenge, source: params[:source], tab: "dashboard"), notice: notice
  end

  def batch_approve_applications
    @challenge = current_user.hosted_challenges.find(params[:id])
    ids = params[:application_ids] || []
    if ids.any?
      apps = @challenge.challenge_applications.where(id: ids, status: :pending)
      apps.each do |app|
        ActiveRecord::Base.transaction do
          app.update!(status: :approved)
          @challenge.participants.create!(
            user: app.user,
            joined_at: Time.current,
            refund_bank_name: app.refund_bank_name,
            refund_account_number: app.refund_account_number,
            refund_account_name: app.refund_account_name
          )
          # Notification
          Notification.create!(
            user: app.user,
            title: "신청 승인 완료",
            content: "'#{@challenge.title}' 챌린지 신청이 승인되었습니다!",
            link: challenge_path(@challenge, source: "prototype"),
            notification_type: :challenge_approval
          )
        end
      end
      notice = "#{apps.count}건의 신청을 승인했습니다."
    else
      notice = "선택된 항목이 없습니다."
    end
    redirect_to hosted_challenge_path(@challenge, source: params[:source], tab: "applications"), notice: notice
  end

  def batch_reject_applications
    @challenge = current_user.hosted_challenges.find(params[:id])
    ids = params[:application_ids] || []
    reason = params[:reject_reason]
    if ids.any?
      apps = @challenge.challenge_applications.where(id: ids, status: :pending)
      apps.each do |app|
        app.update(status: :rejected, reject_reason: reason)
        Notification.create!(
          user: app.user,
          title: "신청 반려 안내",
          content: "'#{@challenge.title}' 챌린지 신청이 반려되었습니다.",
          link: challenge_path(@challenge, source: "prototype"),
          notification_type: :challenge_rejection
        )
      end
      notice = "#{apps.count}건의 신청을 반려했습니다."
    else
      notice = "선택된 항목이 없습니다."
    end
    redirect_to hosted_challenge_path(@challenge, source: params[:source], tab: "applications"), notice: notice
  end

  def nudge_participants
    @challenge = current_user.hosted_challenges.find(params[:id])
    group = params[:group]
    content = params[:content]

    if content.blank?
      redirect_path = params[:source] == "prototype" ? hosted_challenge_path(@challenge, tab: params[:tab], source: "prototype") : hosted_challenge_path(@challenge, tab: params[:tab])
      redirect_to request.referer || redirect_path, alert: "독려 메시지 내용을 입력해주세요."
      return
    end

    target_participants = case group
    when "sluggish"
      @challenge.participants.where(status: :lagging)
    when "unverified_today"
      @challenge.participants.where(today_verified: [ false, nil ])
    when "all"
      @challenge.participants
    else
      []
    end

    if target_participants.any?
      names = target_participants.limit(5).map { |p| p.user.nickname }
      names_text = names.join(", ")
      names_text += " 외 #{target_participants.count - 5}명" if target_participants.count > 5

      target_participants.each do |p|
        Notification.create!(
          user: p.user,
          title: "운영자 독려 메시지",
          content: content,
          link: challenge_path(@challenge, source: "prototype"),
          notification_type: :nudge
        )
      end
      notice = "#{names_text}님에게 독려 메시지를 성공적으로 발송했습니다. (총 #{target_participants.count}명)"
    else
      notice = "발송 대상 루퍼가 없어 메시지를 보내지 않았습니다."
    end

    redirect_to request.referer || hosted_challenge_path(@challenge, source: params[:source]), notice: notice
  end

  private

  def challenge_params
    params.require(:challenge).permit(
      :title, :summary, :description, :custom_host_bio,
      :start_date, :end_date, :category,
      :cost_type, :amount, :max_participants, :failure_tolerance, :penalty_per_failure,
      :full_refund_threshold, :refund_date, :bonus_threshold,
      :verification_start_time, :verification_end_time, :re_verification_allowed,
      :mission_requires_host_approval, :verification_type,
      :host_bank, :host_account, :host_account_holder,
      :certification_goal, :daily_goals, :reward_policy,
      :active_rate_threshold,
      :sluggish_rate_threshold,
      :non_participating_failures_threshold,
      :thumbnail_image,
      :chat_link, :is_private, :admission_type,
      :recruitment_start_date, :recruitment_end_date,
      :participation_fee,
      days: [],
      meeting_info_attributes: [ :id, :place_name, :address, :meeting_time, :description, :max_attendees, :place_url ]
    )
  end

  def load_dashboard_data
    @participants = @challenge.participants.includes(:user, :verification_logs).order(created_at: :desc)
    @pending_verifications = @challenge.verification_logs.pending.includes(participant: :user).order(created_at: :desc)
    @recent_verifications = @challenge.verification_logs.includes(participant: :user).order(created_at: :desc).limit(20)

    # Trend Data (Last 7 Days)
    @trends = (6.downto(0)).map do |i|
      date = Date.today - i.days
      logs_count = @challenge.verification_logs.where("DATE(created_at) = ?", date).where(status: :approved).count
      rate = @challenge.current_participants > 0 ? (logs_count.to_f / @challenge.current_participants * 100).round(1) : 0
      { date: date.strftime("%m/%d"), rate: rate }
    end

    # Settlement Simulation (for Deposit Challenges)
    if @challenge.cost_type_deposit?
      success_count = @challenge.participants.where("completion_rate >= ?", (@challenge.full_refund_threshold || 0.8) * 100).count
      fail_count = @challenge.current_participants - success_count
      @potential_prize_pool = fail_count * (@challenge.amount || 0)
      @estimated_bonus = success_count > 0 ? (@potential_prize_pool / success_count) : 0
    end
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
