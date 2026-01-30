class ProfilesController < ApplicationController
  before_action :require_login

  def show
    begin
      @user = current_user
      @participations = @user.participations.includes(:challenge).order(created_at: :desc)
      @hosted_challenges = @user.hosted_challenges.includes(:participants).order(created_at: :desc)
      @challenge_applications = @user.challenge_applications.includes(:challenge).order(created_at: :desc)

      # 루파 클럽 (유일한 공식 클럽)
      @official_club = RoutineClub.official.first
      @my_membership = @user.routine_club_members.find_by(routine_club: @official_club)
      @recent_reports = @my_membership ? @user.routine_club_reports.where(routine_club: @official_club).order(start_date: :desc).limit(5) : []

      # 비회원을 위한 실시간 성장 분석 데이터
      if @recent_reports.empty?
        @monthly_log_rate = @user.monthly_routine_log_rate
        @monthly_ach_rate = @user.monthly_achievement_rate
        @growth_identity = @user.current_growth_identity
      end

      # 개인 루틴
      @personal_routines = @user.personal_routines.order(created_at: :desc)

      # 뱃지
      @user_badges = @user.user_badges.includes(:badge).order(granted_at: :desc)
      @recent_badges = @user_badges.limit(4)

      # 리뷰
      @reviews = @user.reviews.includes(:challenge).order(created_at: :desc)

      # 루파 활동
      @rufa_activities = @user.rufa_activities.order(created_at: :desc).limit(10)

      # 호스트 통계
      pending_count = VerificationLog.joins(:challenge).where(challenges: { host_id: @user.id }, status: :pending).count
      @host_stats = {
        total_challenges: @hosted_challenges.count,
        total_participants: @hosted_challenges.sum(:current_participants),
        active_challenges: @hosted_challenges.where("start_date <= ? AND end_date >= ?", Date.current, Date.current).count,
        pending_verifications: pending_count
      }

      # 개최 챌린지별 대기 중인 인증 건수 (N+1 방지)
      @hosted_pending_counts = VerificationLog
        .where(challenge_id: @hosted_challenges.pluck(:id), status: :pending)
        .group(:challenge_id)
        .count

      # 대시보드 요약
      @active_participations = @participations.select { |p| p.challenge&.status_active? }

      # 챌린지 vs 모임 (온/오프라인 모드 기준)
      @challenge_participations = @participations.select { |p| p.challenge&.mode_online? }
      @gathering_participations = @participations.select { |p| p.challenge&.mode_offline? }

      # 내가 개최한 모임
      @hosted_gatherings = @hosted_challenges.select { |c| c.mode_offline? }
      @hosted_online_challenges = @hosted_challenges.select { |c| c.mode_online? }

      # 성장 투자 통계 (실제 기능 대신 기록용)
      @growth_stats = {
        total_invested: @participations.sum { |p| p.challenge&.amount.to_i },
        total_refunded: 0, # 추후 포인트 시스템 연동 시 구현
        expected_refund: @active_participations.sum { |p| p.challenge&.amount.to_i }
      }

      # 성취 매트릭스용 통합 데이터 (최근 1년)
      @activity_data = Hash.new(0)

      # 챌린지 인증
      VerificationLog.joins(participant: :user)
                    .where(users: { id: @user.id })
                    .where(created_at: 1.year.ago..Time.current)
                    .group("DATE(verification_logs.created_at)")
                    .count
                    .each { |date, count| @activity_data[date.to_date] += count }

      # 개인 루틴 완료
      PersonalRoutineCompletion.joins(:personal_routine)
                               .where(personal_routines: { user_id: @user.id })
                               .where(completed_on: 1.year.ago..Date.current)
                               .group(:completed_on)
                               .count
                               .each { |date, count| @activity_data[date] += count }

      # 클럽 출석
      RoutineClubAttendance.joins(:routine_club_member)
                           .where(routine_club_members: { user_id: @user.id })
                           .where(attendance_date: 1.year.ago..Date.current)
                           .group(:attendance_date)
                           .count
                           .each { |date, count| @activity_data[date] += count }

      @monthly_completions = @activity_data.select { |date, _| date >= Date.current.beginning_of_month && date <= Date.current.end_of_month }
    rescue => e
      Rails.logger.error "--------------------------------------------------"
      Rails.logger.error "PROFILES#SHOW ERROR: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      Rails.logger.error "--------------------------------------------------"
      raise e
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "프로필이 업데이트되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def save_account
    @user = current_user
    if @user.update(
      saved_bank_name: params[:bank_name],
      saved_account_number: params[:account_number],
      saved_account_holder: params[:account_holder]
    )
      render json: { status: "success", message: "계좌 정보가 저장되었습니다." }
    else
      render json: { status: "error", message: "저장에 실패했습니다." }, status: :unprocessable_entity
    end
  end

  def get_account
    @user = current_user
    if @user.has_saved_account?
      render json: {
        status: "success",
        bank_name: @user.saved_bank_name,
        account_number: @user.saved_account_number,
        account_holder: @user.saved_account_holder
      }
    else
      render json: { status: "error", message: "저장된 계좌 정보가 없습니다." }, status: :not_found
    end
  end

  def destroy
    @user = current_user

    # 진행 중인 챌린지가 있는지 확인
    active_participations = @user.participations.joins(:challenge).where(challenges: { status: :active })
    active_hosted_challenges = @user.hosted_challenges.where(status: :active)

    if active_participations.any? || active_hosted_challenges.any?
      redirect_to profile_path, alert: "진행 중인 챌린지가 있어 탈퇴할 수 없습니다. 모든 챌린지를 종료한 후 다시 시도해주세요."
      return
    end

    # 세션을 먼저 완전히 초기화 (사용자 삭제 전에 수행)
    reset_session

    # 소프트 삭제 (deleted_at 설정)
    @user.soft_delete

    redirect_to root_path, notice: "회원 탈퇴가 완료되었습니다. 그동안 이용해주셔서 감사합니다."
  end

  private

  def profile_params
    params.require(:user).permit(
      :nickname,
      :bio,
      :avatar,
      :saved_bank_name,
      :saved_account_number,
      :saved_account_holder,
      :phone_number,
      sns_links: [ :instagram, :threads, :blog, :youtube, :twitter ]
    )
  end
end
