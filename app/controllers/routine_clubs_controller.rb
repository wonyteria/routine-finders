class RoutineClubsController < ApplicationController
  before_action :require_login, except: [ :index, :show, :guide ]
  before_action :require_admin, only: [ :new, :create ]
  before_action :set_routine_club, only: [ :show, :edit, :update, :join, :manage, :use_pass, :record, :confirm_payment, :reject_payment, :kick_member, :mark_welcomed, :join_as_host ]
  before_action :set_my_membership, only: [ :show, :use_pass ]

  def index
    @official_club = RoutineClub.official.first
    if @official_club
      redirect_to guide_routine_clubs_path
    else
      redirect_to root_path, alert: "루파 클럽이 존재하지 않습니다."
    end
  end

  def guide
    # Force redirect to the new prototype club join page to avoid legacy UI
    redirect_to prototype_club_join_path
  end

  def show
    # Legacy View Blocker: Redirect all traffic to modern prototype pages

    # 1. If user is a member or host -> Go to Dashboard
    if current_user && (@routine_club.members.confirmed.exists?(user: current_user) || @routine_club.host_id == current_user.id || current_user.admin?)
      return redirect_to prototype_home_path(tab: "club")
    end

    # 2. If user is not yet a member -> Go to Join Page
    redirect_to prototype_club_join_path
  end

  def manage
    # Disable legacy management view; redirect to Admin Center
    redirect_to prototype_admin_clubs_path
  end

  def new
    @routine_club = RoutineClub.new
    @routine_club.rules.build
  end

  def create
    @routine_club = current_user.hosted_routine_clubs.build(routine_club_params)

    if @routine_club.save
      redirect_to prototype_admin_clubs_path, notice: "루틴 클럽이 성공적으로 개설되었습니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to prototype_admin_clubs_path, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id
  end

  def update
    return redirect_to prototype_admin_clubs_path, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    if @routine_club.update(routine_club_params)
      redirect_to prototype_admin_clubs_path, notice: "설정이 성공적으로 저장되었습니다."
    else
      redirect_to prototype_admin_clubs_path, alert: "설정 저장에 실패했습니다."
    end
  end

  def join
    if @routine_club.is_full?
      return redirect_to prototype_club_join_path, alert: "정원이 마감되었습니다."
    end

    if !@routine_club.recruitment_open? && current_user.role != "admin" && params[:beta_test] != "true"
      return redirect_to prototype_club_join_path, alert: "지금은 정기 모집 기간이 아닙니다. 다음 모집 기간에 신청해주세요."
    end

    existing_member = @routine_club.members.find_by(user: current_user)
    if existing_member
      if existing_member.status_kicked?
        # Redirect to a generic safe place (home or join path with alert)
        return redirect_to prototype_club_join_path, alert: "죄송합니다. 이전에 클럽에서 제명된 이력이 있어 가입 신청이 제한됩니다. 문의사항은 관리자에게 연락해 주세요."
      else
        return redirect_to prototype_club_join_path, alert: "이미 가입 신청을 했거나 멤버인 상태입니다."
      end
    end

    join_date = Date.current
    recruiting_start = RoutineClub.recruiting_cycle_start_date(join_date)
    membership_end = @routine_club.get_cycle_end_date(recruiting_start)
    quarterly_fee = @routine_club.calculate_quarterly_fee(join_date)

    join_params = params.require(:routine_club).permit(:depositor_name, :contact_info, :goal, :threads_nickname, :commitment)

    @membership = @routine_club.members.build(
      user: current_user,
      paid_amount: quarterly_fee,
      payment_status: :pending,
      membership_start_date: recruiting_start,
      membership_end_date: membership_end,
      **join_params.to_h.symbolize_keys
    )

    if @membership.save
      RoutineClubNotificationService.notify_host_new_payment(@routine_club, @membership)
      redirect_to prototype_club_join_path, notice: "참여 신청이 완료되었습니다. 입금 확인 후 참여가 승인됩니다."
      nil
    else
      msg = @membership.errors.full_messages.to_sentence || "알 수 없는 오류가 발생했습니다."
      Rails.logger.error "Membership Save Failed: #{msg}"
      redirect_to prototype_club_join_path, alert: "참여 신청에 실패했습니다: #{msg}"
      nil
    end
  end

  def join_as_host
    return redirect_to prototype_home_path(tab: "club"), alert: "이미 참여 중입니다." if @routine_club.members.exists?(user: current_user)
    return redirect_to prototype_home_path(tab: "club"), alert: "호스트만 사용할 수 있는 기능입니다." unless @routine_club.host_id == current_user.id

    membership = @routine_club.members.build(
      user: current_user,
      paid_amount: 0,
      payment_status: :confirmed,
      status: :active,
      membership_start_date: @routine_club.start_date,
      membership_end_date: @routine_club.end_date || Date.new(2099, 12, 31),
      joined_at: Time.current,
      depositor_name: "HOST", # Required by validation if pending? but good to have
      contact_info: current_user.phone_number || "HOST"
    )

    if membership.save
      redirect_to prototype_home_path(tab: "club"), notice: "클럽 멤버로 등록되었습니다. 이제 루틴을 기록할 수 있습니다!"
    else
      redirect_to prototype_admin_clubs_path(id: @routine_club.id), alert: "멤버 등록에 실패했습니다: #{membership.errors.full_messages.to_sentence}"
    end
  end

  def record
    return redirect_to @routine_club, alert: "멤버만 기록할 수 있습니다." unless @my_membership

    attendance = @my_membership.attendances.find_or_initialize_by(
      attendance_date: Date.current,
      routine_club: @routine_club
    )

    # Calculate achievement rate at the moment of recording
    achievement_rate = current_user.daily_achievement_rate(Date.current)

    if attendance.update(status: :present, proof_text: params[:proof_text], achievement_rate: achievement_rate)
      @my_membership.update_attendance_stats!
      @my_membership.update_achievement_stats!

    # Create synergy activity
    RufaActivity.create!(
      user: current_user,
      activity_type: :attendance,
      target_id: attendance.id,
      target_type: "RoutineClubAttendance",
      body: "#{current_user.nickname}님이 오늘 루틴 #{achievement_rate}% 달성을 기록했습니다: \"#{params[:proof_text]}\""
    )

      redirect_back fallback_location: routine_club_path(@routine_club), notice: "오늘의 기록이 저장되었습니다!"
    else
      redirect_back fallback_location: routine_club_path(@routine_club), alert: "기록 저장에 실패했습니다."
    end
  end
  def use_pass
    return redirect_to @routine_club, alert: "멤버십 승인 후 사용할 수 있습니다." unless @my_membership&.payment_status_confirmed?

    # Determine target date
    target_date = params[:date] ? Date.parse(params[:date]) : Date.current
    pass_type = params[:pass_type] || "relax"

    # Check remaining passes based on type
    if pass_type == "save"
      if @my_membership.remaining_save_passes <= 0
        return redirect_to (params[:source] == "prototype" ? prototype_home_path : personal_routines_path(tab: "club")), alert: "세이브권을 모두 소진했습니다. (3/3 사용)"
      end
    else
      if @my_membership.remaining_relax_passes <= 0
        return redirect_to (params[:source] == "prototype" ? prototype_home_path : personal_routines_path(tab: "club")), alert: "휴식권을 모두 소진했습니다. (3/3 사용)"
      end
    end

    # Check attendance for the target date
    target_attendance = @my_membership.attendances.find_by(attendance_date: target_date)
    if target_attendance&.status_present?
      return redirect_to (params[:source] == "prototype" ? prototype_home_path : personal_routines_path(tab: "club")), alert: "해당 날짜(#{target_date})는 이미 출석 처리되었습니다."
    elsif target_attendance&.status_excused?
      return redirect_to (params[:source] == "prototype" ? prototype_home_path : personal_routines_path(tab: "club")), alert: "해당 날짜(#{target_date})에 이미 처리되었습니다."
    end

    success = if pass_type == "save"
                @my_membership.use_save_pass!(target_date)
    else
                @my_membership.use_relax_pass!(target_date)
    end

    if success
      msg = pass_type == "save" ? "세이브권이 성공적으로 사용되었습니다." : "휴식권이 성공적으로 사용되었습니다."
      redirect_to (params[:source] == "prototype" ? prototype_home_path : personal_routines_path(tab: "club")), notice: msg
    else
      redirect_to (params[:source] == "prototype" ? prototype_home_path : personal_routines_path(tab: "club")), alert: "아이템 사용에 실패했습니다."
    end
  end

  def confirm_payment
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    member.confirm_payment!

    redirect_to manage_routine_club_path(@routine_club, tab: "pending"), notice: "#{member.user.nickname}님의 입금이 확인되었습니다."
  end

  def reject_payment
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    member.reject_payment!(params[:reason])

    path = if params[:source] == "prototype" || request.referer&.include?("admin_center/clubs")
             prototype_admin_clubs_path(tab: "members")
    else
             manage_routine_club_path(@routine_club, tab: "pending")
    end
    redirect_to path, notice: "입금이 거부되었습니다."
  end

  def kick_member
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    member.kick!(params[:reason])

    path = if params[:source] == "prototype" || request.referer&.include?("admin_center/clubs")
             prototype_admin_clubs_path(tab: "members")
    else
             manage_routine_club_path(@routine_club, tab: "monthly")
    end
    redirect_to path, notice: "#{member.user.nickname}님이 강퇴되었습니다."
  end

  def warn_member
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    reason = params[:reason].presence || "호스트가 경고를 부여했습니다."
    member.warn!(reason)

    path = if params[:source] == "prototype" || request.referer&.include?("admin_center/clubs")
             prototype_admin_clubs_path(tab: "members")
    else
             manage_routine_club_path(@routine_club, tab: "monthly")
    end
    redirect_to path, notice: "#{member.user.nickname}님에게 경고를 부여했습니다."
  end

  def send_message
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    recipient = User.find(params[:recipient_id])
    message = params[:message]

    if message.present?
      # Create notification for the recipient
      Notification.create!(
        user: recipient,
        title: "#{@routine_club.title} 호스트로부터 메시지",
        content: message,
        notification_type: :club_message,
        link: personal_routines_path(tab: "club")
      )

      path = if params[:source] == "prototype" || request.referer&.include?("admin_center/clubs")
               prototype_admin_clubs_path(tab: "members")
      else
               manage_routine_club_path(@routine_club, tab: "monthly")
      end
      redirect_to path, notice: "#{recipient.nickname}님에게 메시지를 전송했습니다."
    else
      redirect_to manage_routine_club_path(@routine_club, tab: "monthly"), alert: "메시지 내용을 입력해주세요."
    end
  end

  def mark_welcomed
    membership = @routine_club.members.find_by(user: current_user, payment_status: :confirmed)

    if membership
      membership.update(welcomed: true)
      redirect_to personal_routines_path(tab: "club"), notice: "루파 클럽에 오신 것을 환영합니다! 🎉"
    else
      redirect_to root_path, alert: "멤버십을 찾을 수 없습니다."
    end
  end

  private

  def set_routine_club
    @routine_club = RoutineClub.find(params[:id])
  end

  def set_my_membership
    return unless current_user
    @my_membership = @routine_club.members.find_by(user: current_user)

    # If admin/host doesn't have a membership record, create a virtual one or actual one
    # For now, let's ensure they have a record if they are admins to avoid nil errors in dashboard
    if !@my_membership && current_user.admin?
      @my_membership = @routine_club.members.create!(
        user: current_user,
        payment_status: :confirmed,
        status: :active,
        paid_amount: 1, # Dummy
        joined_at: Time.current,
        membership_start_date: @routine_club.start_date,
        membership_end_date: @routine_club.end_date
      )
    end
  end

  def routine_club_params
    params.require(:routine_club).permit(
      :title, :description, :category, :thumbnail,
      :start_date, :end_date, :monthly_fee, :min_duration_months, :max_members,
      :bank_name, :account_number, :account_holder,
      :weekly_reward_info, :monthly_reward_info, :season_reward_info,
      :zoom_link, :special_lecture_link,
      rules_attributes: [ :id, :title, :description, :rule_type, :has_penalty, :penalty_description, :penalty_points, :auto_kick_enabled, :auto_kick_threshold, :position, :_destroy ]
    )
  end
end
