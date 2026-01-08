class RoutineClubsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :require_admin, only: [ :new, :create ]
  before_action :set_routine_club, only: [ :show, :edit, :update, :join, :manage, :use_pass, :record, :confirm_payment, :reject_payment, :kick_member ]
  before_action :set_my_membership, only: [ :show, :use_pass ]

  def index
    @routine_clubs = RoutineClub.recruiting_clubs
                                  .includes(:host, :members)
                                  .order(created_at: :desc)

    if params[:category].present?
      @routine_clubs = @routine_clubs.by_category(params[:category])
    end

    @my_clubs = current_user&.routine_club_members&.includes(:routine_club) || []
  end

  def guide
  end

  def show
    @is_member = current_user && (@routine_club.members.exists?(user: current_user) || current_user.admin?)
    @is_host = current_user && (@routine_club.host_id == current_user.id || current_user.super_admin?)

    # Default to dashboard if member/admin and no tab specified
    if params[:tab].blank? && @is_member
      params[:tab] = "dashboard"
    end

    if @my_membership
       @my_membership.recalculate_growth_points!
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
  end

  def manage
    return redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host_id == current_user.id

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

    # Community Data
    @announcements = @routine_club.announcements.order(created_at: :desc)
    @gatherings = @routine_club.gatherings.order(gathering_at: :asc)
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
  end

  def update
    return redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host_id == current_user.id

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

    if !@routine_club.recruitment_open? && current_user.role != "admin"
      return redirect_to @routine_club, alert: "지금은 정기 모집 기간이 아닙니다. 다음 모집 기간에 신청해주세요."
    end

    if @routine_club.members.exists?(user: current_user)
      return redirect_to @routine_club, alert: "이미 가입 신청을 했거나 멤버인 상태입니다."
    end

    join_date = Date.current
    quarterly_fee = @routine_club.calculate_quarterly_fee(join_date)

    @membership = @routine_club.members.build(
      user: current_user,
      paid_amount: quarterly_fee,
      depositor_name: params[:depositor_name],
      contact_info: params[:contact_info],
      threads_nickname: params[:threads_nickname],
      payment_status: :pending
    )

    if @membership.save
      RoutineClubNotificationService.notify_host_new_payment(@routine_club, @membership)
      redirect_to @routine_club, notice: "참여 신청이 완료되었습니다. 입금 확인 후 참여가 승인됩니다."
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
        body: "#{current_user.nickname}님이 오늘 루틴 #{achievement_rate}% 달성을 기록했습니다: \"#{params[:proof_text]}\""
      )

      redirect_back fallback_location: routine_club_path(@routine_club), notice: "오늘의 기록이 저장되었습니다!"
    else
      redirect_back fallback_location: routine_club_path(@routine_club), alert: "기록 저장에 실패했습니다."
    end
  end
  def use_pass
    return redirect_to @routine_club, alert: "멤버만 사용할 수 있습니다." unless @my_membership

    # Check remaining passes
    if @my_membership.used_passes_count.to_i >= 3
      return redirect_to personal_routines_path(tab: "club"), alert: "휴식권을 모두 소진했습니다. (3/3 사용)"
    end

    # Check today's attendance
    today_attendance = @my_membership.attendances.find_by(attendance_date: Date.current)
    if today_attendance&.status_present?
      return redirect_to personal_routines_path(tab: "club"), alert: "이미 오늘 출석 처리되었습니다. 휴식권을 사용할 수 없습니다."
    elsif today_attendance&.status_excused?
      return redirect_to personal_routines_path(tab: "club"), alert: "오늘 이미 휴식권을 사용했습니다."
    end

    if @my_membership.use_relaxation_pass!
      redirect_to personal_routines_path(tab: "club"), notice: "휴식권이 성공적으로 사용되었습니다. 오늘 루틴은 면제 처리됩니다."
    else
      redirect_to personal_routines_path(tab: "club"), alert: "휴식권 사용에 실패했습니다. 관리자에게 문의해주세요."
    end
  end

  def confirm_payment
    return redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    member.confirm_payment!

    redirect_to @routine_club, notice: "#{member.user.nickname}님의 입금이 확인되었습니다."
  end

  def reject_payment
    return redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    member.reject_payment!(params[:reason])

    redirect_to @routine_club, notice: "입금이 거부되었습니다."
  end

  def kick_member
    return redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host_id == current_user.id

    member = @routine_club.members.find(params[:member_id])
    member.kick!(params[:reason])

    redirect_to @routine_club, notice: "#{member.user.nickname}님이 강퇴되었습니다."
  end

  def cheer
    attendance = RoutineClubAttendance.find(params[:attendance_id])

    # Cannot cheer for self
    if attendance.routine_club_member.user_id == current_user.id
      return respond_to do |format|
        format.html { redirect_back fallback_location: personal_routines_path(tab: "club"), alert: "본인의 기록은 응원할 수 없습니다." }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("body", html: "<div class='fixed top-20 left-1/2 -translate-x-1/2 z-[100] bg-rose-600 text-white px-6 py-3 rounded-2xl shadow-2xl font-black animate-bounce' onclick='this.remove()'>⚠️ 본인의 기록은 응원할 수 없습니다!</div>") }
      end
    end

    attendance.add_cheer(current_user.id)
    attendance.routine_club_member.recalculate_growth_points!

    respond_to do |format|
      format.html { redirect_back fallback_location: personal_routines_path(tab: "club"), notice: "응원을 보냈습니다!" }
      format.turbo_stream
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
      rules_attributes: [ :id, :title, :description, :rule_type, :has_penalty, :penalty_description, :penalty_points, :auto_kick_enabled, :auto_kick_threshold, :position, :_destroy ]
    )
  end
end
