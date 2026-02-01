class RoutineClubsController < ApplicationController
  before_action :require_login, except: [ :index, :show, :guide ]
  before_action :require_admin, only: [ :new, :create ]
  before_action :set_routine_club, only: [ :show, :edit, :update, :join, :manage, :use_pass, :record, :confirm_payment, :reject_payment, :kick_member, :mark_welcomed ]
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
    @is_member = current_user && (@routine_club.members.confirmed.exists?(user: current_user) || current_user.admin?)
    @is_host = current_user && (@routine_club.host_id == current_user.id || current_user.super_admin?)

    # Redirect members to their club dashboard (Only for Official Club)
    if @is_member && !@is_host && @routine_club.is_official?
      return redirect_to personal_routines_path(tab: "club")
    end

    # Default to dashboard if member/admin and no tab specified
    if params[:tab].blank? && @is_member
      params[:tab] = "dashboard"
    end

    if @my_membership
       @my_membership.recalculate_growth_points!
    end

    # Calculate Rank Percentile
    if @my_membership && @my_membership.status_active?
      active_members = @routine_club.members.active
      total_members = active_members.count
      if total_members > 0
        my_rate = @my_membership.achievement_rate.to_f
        better_count = active_members.where("achievement_rate > ?", my_rate).count
        @my_rank_percentile = ((better_count + 1).to_f / total_members * 100).ceil
      else
        @my_rank_percentile = 0
      end
    end

    @members = @routine_club.members.includes(:user).where(payment_status: :confirmed)
    @rankings = @members.order(growth_points: :desc).limit(10)

    @pending_payments = @is_host ? @routine_club.members.where(payment_status: :pending) : []
    @rules = @routine_club.rules.order(:position)

    # Community Data
    @announcements = @routine_club.announcements.order(created_at: :desc)
    @gatherings = @routine_club.gatherings.order(gathering_at: :asc)

    # User Routines for Dashboard Checklist
    @personal_routines = current_user&.personal_routines&.includes(:completions)&.order(created_at: :desc) || []
    @daily_achievement_rate = current_user&.daily_achievement_rate(Date.current) || 0
    @member_days = current_user&.rufa_member_days || 0
    @my_score = current_user&.rufa_club_score || 0

    active_members = @routine_club.members.active
    @rufa_rankings = active_members.map { |m| { user: m.user, score: m.growth_points || 0 } }.sort_by { |r| -r[:score] }.take(10)
    @top_avg_score = @rufa_rankings.any? ? (@rufa_rankings.sum { |r| r[:score] } / @rufa_rankings.size).round(1) : 0
    @category_stats = current_user&.category_stats || {}
  end

  def manage
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    @members = @routine_club.members.includes(:user).where(payment_status: :confirmed)
    @pending_payments = @routine_club.members.where(payment_status: :pending)

    # Calculate Monthly vs Cumulative
    current_month_range = Time.current.all_month

    @member_stats = @members.map do |m|
      monthly_atts = m.attendances.where(attendance_date: current_month_range)
      monthly_present = monthly_atts.where(status: [ :present, :excused ]).count
      monthly_total = monthly_atts.count
      monthly_rate = monthly_total > 0 ? (monthly_present.to_f / monthly_total * 100).round(2) : 0.0

      # Get user's ongoing challenges
      ongoing_challenges = m.user.participations
                            .joins(:challenge)
                            .where(status: :approved)
                            .where("challenges.start_date <= ? AND challenges.end_date >= ?", Date.current, Date.current)
                            .includes(:challenge)
                            .limit(5) # Limit to 5 to avoid clutter

      {
        membership: m,
        monthly_rate: monthly_rate,
        monthly_absence: monthly_total - monthly_present,
        cumulative_rate: m.attendance_rate,
        cumulative_points: m.growth_points || 0,
        ongoing_challenges: ongoing_challenges
      }
    end

    # Default sort for Monthly
    @monthly_sorted = @member_stats.sort_by { |s| -s[:monthly_rate] }
    # Default sort for Cumulative
    @cumulative_sorted = @member_stats.sort_by { |s| -s[:cumulative_points] }

    # Additional Statistics
    # 1. 운영 일수
    @days_running = (Date.current - @routine_club.start_date).to_i
    @total_days = (@routine_club.end_date - @routine_club.start_date).to_i

    # 2. 이번 주 출석률
    week_range = (Date.current - 6.days)..Date.current
    week_attendances = @routine_club.attendances.where(attendance_date: week_range)
    week_present = week_attendances.where(status: [ :present, :excused ]).count
    week_total = week_attendances.count
    @weekly_attendance_rate = week_total > 0 ? (week_present.to_f / week_total * 100).round(1) : 0.0

    # 3. 저조한 멤버 수 (출석률 60% 미만)
    @low_performers_count = @members.select { |m| m.attendance_rate < 60 }.count

    # Community Data
    @announcements = @routine_club.announcements.order(created_at: :desc)
    @gatherings = @routine_club.gatherings.order(gathering_at: :asc)

    if params[:source] == "prototype"
      render "prototype/club_manage", layout: "prototype"
    end
  end

  def new
    @routine_club = RoutineClub.new
    @routine_club.rules.build
  end

  def create
    @routine_club = current_user.hosted_routine_clubs.build(routine_club_params)

    if @routine_club.save
      redirect_to @routine_club, notice: "루틴 클럽이 성공적으로 개설되었습니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id
  end

  def update
    return redirect_to @routine_club, alert: "권한이 없습니다." unless current_user.admin? || @routine_club.host_id == current_user.id

    if @routine_club.update(routine_club_params)
      redirect_to manage_routine_club_path(@routine_club), notice: "설정이 성공적으로 저장되었습니다."
    else
      redirect_to manage_routine_club_path(@routine_club), alert: "설정 저장에 실패했습니다."
    end
  end

  def join
    if @routine_club.is_full?
      return redirect_to @routine_club, alert: "정원이 마감되었습니다."
    end

    if !@routine_club.recruitment_open? && current_user.role != "admin" && params[:beta_test] != "true"
    return redirect_to @routine_club, alert: "지금은 정기 모집 기간이 아닙니다. 다음 모집 기간에 신청해주세요."
    end

    existing_member = @routine_club.members.find_by(user: current_user)
    if existing_member
      if existing_member.status_kicked?
        return redirect_to @routine_club, alert: "죄송합니다. 이전에 클럽에서 제명된 이력이 있어 가입 신청이 제한됩니다. 문의사항은 관리자에게 연락해 주세요."
      else
        return redirect_to @routine_club, alert: "이미 가입 신청을 했거나 멤버인 상태입니다."
      end
    end

    join_date = Date.current
    quarterly_fee = @routine_club.calculate_quarterly_fee(join_date)

    @membership = @routine_club.members.build(
      user: current_user,
      paid_amount: quarterly_fee,
      depositor_name: params[:depositor_name],
      contact_info: params[:contact_info],
      goal: params[:goal],
      threads_nickname: params[:threads_nickname],
      commitment: params[:commitment],
      payment_status: :pending
    )

    if @membership.save
      RoutineClubNotificationService.notify_host_new_payment(@routine_club, @membership)
      if params[:source] == "prototype" || request.referer&.include?("prototype")
        redirect_to prototype_home_path(joined_club: true, club_id: @routine_club.id), notice: "참여 신청이 완료되었습니다. 입금 확인 후 참여가 승인됩니다."
      else
        redirect_to @routine_club, notice: "참여 신청이 완료되었습니다. 입금 확인 후 참여가 승인됩니다."
      end
    else
      redirect_to @routine_club, alert: "참여 신청에 실패했습니다."
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

  def cheer
    @attendance = RoutineClubAttendance.find(params[:attendance_id])

    # Cannot cheer for self
    if @attendance.routine_club_member.user_id == current_user.id
      return respond_to do |format|
        format.html { redirect_back fallback_location: personal_routines_path(tab: "club"), alert: "본인의 기록은 응원할 수 없습니다." }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("body", html: "<div class='fixed top-20 left-1/2 -translate-x-1/2 z-[100] bg-rose-600 text-white px-6 py-3 rounded-2xl shadow-2xl font-black animate-bounce' onclick='this.remove()'>⚠️ 본인의 기록은 응원할 수 없습니다!</div>") }
      end
    end

    # Toggle cheer
    if @attendance.cheered_by?(current_user.id)
      @attendance.remove_cheer(current_user.id)
      action_notice = "응원을 취소했습니다."
    else
      @attendance.add_cheer(current_user.id)
      action_notice = "응원을 보냈습니다!"
    end

    # Synchronize with RufaClap if a related synergy activity exists
    activity = RufaActivity.find_by(target_id: @attendance.id, target_type: "RoutineClubAttendance")
    if activity
      clap = current_user.rufa_claps.find_by(rufa_activity: activity)
      if clap && action_notice.include?("취소")
        clap.destroy
      elsif !clap && action_notice.include?("보냈습니다")
        current_user.rufa_claps.create(rufa_activity: activity)
      end
    end

    @attendance.routine_club_member.recalculate_growth_points!

    respond_to do |format|
      format.html { redirect_back fallback_location: personal_routines_path(tab: "club"), notice: action_notice }
      format.turbo_stream { render :cheer, formats: [ :turbo_stream ] }
    end
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
        message: message,
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
