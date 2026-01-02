class RoutineClubsController < ApplicationController
  before_action :require_login, except: [ :index, :show ]
  before_action :require_admin, only: [ :new, :create ]
  before_action :set_routine_club, only: [ :show, :manage, :update, :join, :use_pass, :confirm_payment, :reject_payment, :kick_member ]

  def index
    @routine_clubs = RoutineClub.recruiting_clubs
                                  .includes(:host, :members)
                                  .order(created_at: :desc)

    if params[:category].present?
      @routine_clubs = @routine_clubs.by_category(params[:category])
    end

    @my_clubs = current_user&.routine_club_members&.includes(:routine_club) || []
  end

  def show
    @is_member = current_user && @routine_club.members.exists?(user: current_user)
    @my_membership = current_user && @routine_club.members.find_by(user: current_user)
    @is_host = current_user && @routine_club.host_id == current_user.id

    if @my_membership
       @my_membership.recalculate_growth_points!
    end

    @members = @routine_club.members.includes(:user).where(payment_status: :confirmed)
    @rankings = @members.order(growth_points: :desc).limit(10)

    @pending_payments = @is_host ? @routine_club.members.where(payment_status: :pending) : []
    @rules = @routine_club.rules.order(:position)
  end

  def manage
    return redirect_to @routine_club, alert: "권한이 없습니다." unless @routine_club.host_id == current_user.id

    @members = @routine_club.members.includes(:user).where(payment_status: :confirmed)
    @pending_payments = @routine_club.members.where(payment_status: :pending)
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

    join_date = Date.current
    prorated_fee = @routine_club.calculate_prorated_fee(join_date)

    @membership = @routine_club.members.build(
      user: current_user,
      paid_amount: prorated_fee,
      depositor_name: params[:depositor_name],
      contact_info: params[:contact_info],
      payment_status: :pending
    )

    if @membership.save
      RoutineClubNotificationService.notify_host_new_payment(@routine_club, @membership)
      redirect_to @routine_club, notice: "참여 신청이 완료되었습니다. 입금 확인 후 참여가 승인됩니다."
    else
      redirect_to @routine_club, alert: "참여 신청에 실패했습니다."
    end
  end

  def use_pass
    return redirect_to @routine_club, alert: "멤버만 사용할 수 있습니다." unless @my_membership

    if @my_membership.use_relaxation_pass!
      redirect_to routine_club_path(@routine_club, tab: "dashboard"), notice: "휴식권이 성공적으로 사용되었습니다. 오늘 루틴은 면제 처리됩니다."
    else
      redirect_to routine_club_path(@routine_club, tab: "dashboard"), alert: "휴식권을 사용할 수 없는 상태이거나 횟수를 모두 소진했습니다."
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

  private

  def set_routine_club
    @routine_club = RoutineClub.find(params[:id])
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
