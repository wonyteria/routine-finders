class PersonalRoutinesController < ApplicationController
  before_action :require_login
  before_action :set_routine, only: [ :edit, :update, :toggle, :destroy ]

  def index
    return redirect_to login_path unless logged_in?

    # 개인 루틴 (무료)
    current_user.user_badges.where(is_viewed: false).update_all(is_viewed: true)

    @selected_date = begin
      params[:date].present? ? Date.parse(params[:date]) : Date.current
    rescue
      Date.current
    end

    # Filter routines that were active on the selected date
    if @selected_date == Date.current
      @personal_routines = current_user.personal_routines.includes(:completions)
                                       .where("created_at <= ?", @selected_date.end_of_day)
                                       .where(deleted_at: nil)
                                       .order(created_at: :desc)
    else
      @personal_routines = current_user.personal_routines.includes(:completions)
                                       .where("created_at <= ?", @selected_date.end_of_day)
                                       .where("deleted_at IS NULL OR deleted_at > ?", @selected_date.end_of_day)
                                       .order(created_at: :desc)
    end

    set_activity_data

    # 루파 클럽 공식 확보 (없을 경우 자동 생성)
    @official_club = RoutineClub.ensure_official_club
    unless @official_club
      return redirect_to root_path, alert: "루파 클럽 정보를 서버에서 초기화할 수 없습니다."
    end

    # 관리자는 자동으로 공식 클럽 멤버로 등록 (레코드가 없을 경우)
    if current_user.admin? && !current_user.routine_club_members.exists?(routine_club: @official_club)
      current_user.routine_club_members.create!(
        routine_club: @official_club,
        payment_status: :confirmed,
        status: :active,
        paid_amount: 1, # Dummy amount for admins
        joined_at: Time.current,
        membership_start_date: @official_club.start_date,
        membership_end_date: @official_club.end_date
      )
    end

    # 루파 클럽 (유료) 관련 통계 및 랭킹
    @routine_clubs = RoutineClub.recruiting_clubs.includes(:host, :members).order(created_at: :desc).limit(6)
    @my_club_memberships = current_user.routine_club_members.includes(:routine_club).where(status: [ :active, :warned ])
    @my_club_memberships.each do |m|
      if m.identity_title.blank?
        m.update(identity_title: "시작하는 파인더")
      end
    end
    @pending_payments = current_user.routine_club_members.where(payment_status: :pending)

    @my_official_membership = current_user.routine_club_members.find_by(routine_club: @official_club)
    @is_official_host = current_user.admin? || (@official_club && @official_club.host_id == current_user.id)

    # 루파 클럽 공식 공지사항
    if @official_club && Announcement.where(routine_club: @official_club).none?
      @official_club.announcements.create!(title: "루파 클럽에 오신 것을 환영합니다! 목표 설정을 시작해보세요.", content: "내용")
      @official_club.announcements.create!(title: "1월 오프라인 정기 모임 일정 안내", content: "내용")
    end
    @rufa_announcements = @official_club ? Announcement.where(routine_club: @official_club).recent.limit(5) : []

    # Standard variables for club dashboard partial
    @routine_club = @official_club
    @my_membership = @my_official_membership
    @is_host = @is_official_host
    @announcements = @official_club ? @official_club.announcements.order(created_at: :desc) : []
    @gatherings = @official_club ? @official_club.gatherings.order(gathering_at: :asc) : []

    # Calculate Rank Percentile for Dashboard
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

    # 유저 목표 (단기/중기/장기)
    @user_goals = current_user.user_goals.index_by(&:goal_type)
    @short_term_goal = @user_goals["short_term"]&.body
    @mid_term_goal = @user_goals["mid_term"]&.body
    @long_term_goal = @user_goals["long_term"]&.body

    # 루파 클럽 멤버 랭킹 (상위 10명)
    @rufa_rankings = User.joins(:routine_club_members)
                         .where(routine_club_members: { status: :active })
                         .distinct
                         .map { |u| { user: u, score: u.rufa_club_score } }
                         .sort_by { |r| -r[:score] }
                         .take(10)

    @top_avg_score = @rufa_rankings.any? ? (@rufa_rankings.sum { |r| r[:score] } / @rufa_rankings.size).round(1) : 0
    @my_score = current_user.rufa_club_score

    # 누적 랭킹 (All-time)
    @lifetime_rankings = User.joins(:routine_club_members)
                             .where(routine_club_members: { status: :active })
                             .distinct
                             .map { |u| { user: u, score: u.lifetime_rufa_score } }
                             .sort_by { |r| -r[:score] }
                             .take(10)

    # 루파 통계 (요약)
    @current_log_rate = current_user.monthly_routine_log_rate
    @current_achievement_rate = current_user.monthly_achievement_rate
    @daily_achievement_rate = current_user.daily_achievement_rate(@selected_date)
    @total_completions = current_user.total_routine_completions
    @member_days = current_user.rufa_member_days
    @todays_routines = current_user.personal_routines.select { |r| (r.days || []).include?(Date.current.wday.to_s) }

    # Permission Service for Unified View
    @permission = PermissionService.new(current_user)

    # 루파 클럽 멤버 랭킹 (상위 3명 - 포디움용)
    @top_rankings = @rufa_rankings.take(3)
    @other_rankings = @rufa_rankings[3..] || []

    # 전문가 템플릿 (Mock or Real)
    @routine_templates = RoutineTemplate.limit(4)
    if @routine_templates.none?
      # 임시 데이터 생성
      [
        { title: "새벽 5시 미라클 모닝", author: "김갓생", category: "HEALTH", icon: "☀️", desc: "새벽 시간을 활용한 압도적 효율의 아침 루틴" },
        { title: "딥 워크(Deep Work) 몰입", author: "이성공", category: "STUDY", icon: "🧠", desc: "고도의 집중력을 끌어올리는 업무/공부 전 루틴" }
      ].each do |t|
        RoutineTemplate.create!(title: t[:title], author_name: t[:author], category: t[:category], icon: t[:icon], description: t[:desc], days: "1,2,3,4,5")
      end
      @routine_templates = RoutineTemplate.all
    end

    # 루파 시너지 피드
    @rufa_activities = RufaActivity.includes(:user, :claps).recent.limit(10)

    # 루파 인사이트 (전문가 템플릿)
    if RoutineTemplate.none?
      RoutineTemplate.create!(title: "미라클 모닝 영양팩", description: "성공하는 리더들의 아침 필수 영양제 세트", category: "HEALTH", icon: "💊", days: "1,2,3,4,5", author_name: "루파 가이드")
      RoutineTemplate.create!(title: "퇴근 후 10분 마인드셋", description: "하루의 스트레스를 리셋하는 명상 루틴", category: "MIND", icon: "🧘", days: "1,2,3,4,5", author_name: "마인드 마스터")
    end
    @routine_templates = RoutineTemplate.all

    # 현재 사용자의 루파 상태
    @current_log_rate = current_user.monthly_routine_log_rate
    @current_achievement_rate = current_user.monthly_achievement_rate
    set_recommended_routines

    # 루파 성장 레이더용 카테고리별 통계
    @category_stats = current_user.category_stats

    # 점수 트렌드 (최근 7일간의 달성률 변화)
    @achievement_trend = (0..6).map do |i|
      date = i.days.ago.to_date
      completions = current_user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: date }).count
      total = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }.count
      total > 0 ? (completions.to_f / total * 100).round : 0
    end.reverse
  end

  def create
    if params[:personal_routine] && params[:personal_routine][:days].is_a?(String)
      begin
        params[:personal_routine][:days] = JSON.parse(params[:personal_routine][:days]).map(&:to_s)
      rescue JSON::ParserError
        # Keep as is or handle error
      end
    end
    @routine = current_user.personal_routines.build(routine_params)

    if @routine.save
      @personal_routines = current_user.personal_routines.includes(:completions).order(created_at: :desc)
      @selected_date = params[:date] || Date.current
      set_activity_data
      set_recommended_routines
      respond_to do |format|
        format.html do
          if params[:source] == "prototype"
            redirect_to prototype_routines_path, notice: "새로운 루틴이 추가되었습니다!"
          else
            redirect_to personal_routines_path(tab: "personal"), notice: "Personal routine was successfully created."
          end
        end
        format.turbo_stream
        format.json { render :show, status: :created, location: @routine }
      end
    else
      redirect_to personal_routines_path(date: params[:date], tab: params[:tab]), alert: @routine.errors.full_messages.to_sentence
    end
  end

  def edit
    # Allow editing regardless of date
  end

  def update
    if params[:personal_routine] && params[:personal_routine][:days].is_a?(String)
      begin
        params[:personal_routine][:days] = JSON.parse(params[:personal_routine][:days]).map(&:to_s)
      rescue JSON::ParserError
      end
    end

    if @routine.update(routine_params)
      respond_to do |format|
        set_recommended_routines
        format.html do
          if params[:source] == "prototype"
            redirect_to prototype_routines_path, notice: "루틴이 수정되었습니다!"
          else
            redirect_to personal_routines_path(date: params[:date], tab: params[:tab]), notice: "루틴이 수정되었습니다!"
          end
        end
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle
    target_date = params[:date] ? Date.parse(params[:date]) : Date.current

    if target_date != Date.current
      return respond_to do |format|
        format.html { redirect_back fallback_location: personal_routines_path, alert: "루틴 체크는 당일에만 가능합니다." }
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.append("body", html: "<script>alert('루틴 체크는 당일에만 가능합니다.');</script>"),
            turbo_stream.prepend("body", html: "<div class='fixed top-20 left-1/2 -translate-x-1/2 z-[100] bg-rose-600 text-white px-6 py-3 rounded-2xl shadow-2xl font-black animate-bounce' onclick='this.remove()'>⚠️ 루틴 체크는 당일에만 가능합니다!</div>")
          ]
        }
      end
    end

    @routine.toggle_completion!(target_date)
    BadgeService.new(current_user).check_and_award_all!
    set_activity_data
    set_recommended_routines
    @selected_date = target_date

    # 뷰 렌더링에 필요한 변수 설정 (현재 선택된 날짜 기준)
    @selected_date = target_date

    # 루파 클럽 멤버라면 달성률 통계 업데이트 및 자동 기록 체크
    @official_club = RoutineClub.official.first
    @my_membership = current_user.routine_club_members.find_by(routine_club: @official_club)
    @routine_club = @official_club

    if current_user.is_rufa_club_member?
      current_user.routine_club_members.active.each do |m|
        attendance = m.attendances.find_or_initialize_by(attendance_date: target_date, routine_club: m.routine_club)
        achievement_rate = current_user.daily_achievement_rate(target_date)

        # 1. 출석 상태 업데이트: 성취도가 0보다 크면 'present'로 표시 (실시간 반영)
        if achievement_rate > 0
          attendance.status = :present
          attendance.achievement_rate = achievement_rate

          # 100% 첫 달성 시 자동 기록 문구 추가
          if achievement_rate >= 100.0 && !attendance.proof_text.present?
            attendance.proof_text = "오늘의 루틴을 모두 완료했습니다! (자동 기록)"
          end
          attendance.save!
        else
          # 모두 해제했을 경우 기록이 있으면 달성률 0으로 업데이트하고 상태를 absent로 변경하여 통계에서 제외
          if attendance.persisted?
            attendance.update(achievement_rate: 0, status: :absent)
          end
        end

        m.update_attendance_stats!
        m.update_achievement_stats!
        m.recalculate_growth_points!
      end
      @my_membership&.reload
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: personal_routines_path(date: @selected_date, tab: params[:tab]) }
      format.turbo_stream
    end
  end

  def update_goals
    [ :short_term, :mid_term, :long_term ].each do |type|
      if params[type].present?
        goal = current_user.user_goals.find_or_initialize_by(goal_type: type)
        is_new = goal.new_record? || goal.body != params[type]
        if goal.update(body: params[type]) && is_new && current_user.is_rufa_club_member?
          RufaActivity.create_goal_activity(current_user, goal)
        end
      end
    end
    redirect_to personal_routines_path(tab: "club"), notice: "목표가 저장되었습니다."
  end

  def destroy
    target_date = params[:date] ? Date.parse(params[:date]) : Date.current
    if target_date != Date.current
      return respond_to do |format|
        format.html { redirect_back fallback_location: personal_routines_path, alert: "루틴 삭제는 오늘 날짜에서만 가능합니다." }
        format.turbo_stream { render turbo_stream: turbo_stream.append("body", html: "<script>alert('루틴 삭제는 오늘 날짜에서만 가능합니다.');</script>") }
      end
    end

    @routine.update(deleted_at: Time.current)
    set_activity_data
    set_recommended_routines
    @selected_date = params[:date] ? Date.parse(params[:date]) : Date.current
    @personal_routines = current_user.personal_routines.includes(:completions)
                                     .where("created_at <= ?", @selected_date.end_of_day)
                                     .where(deleted_at: nil)
                                     .order(created_at: :desc)

    respond_to do |format|
      format.html do
        if params[:source] == "prototype"
          redirect_to prototype_routines_path, notice: "루틴이 삭제되었습니다."
        else
          redirect_to personal_routines_path(date: params[:date], tab: params[:tab]), notice: "루틴이 삭제되었습니다."
        end
      end
      format.turbo_stream
    end
  end

  private

  def set_activity_data
    @activity_data = current_user.personal_routines.joins(:completions)
                                 .where(personal_routine_completions: { completed_on: 1.year.ago..Date.current })
                                 .group("personal_routine_completions.completed_on")
                                 .count
    @monthly_completions = @activity_data.select { |date, _| date >= Date.current.beginning_of_month && date <= Date.current.end_of_month }
  end

  def set_recommended_routines
    @recommended_routines = [
      { title: "아침 물 한 잔 마시기", category: "HEALTH", icon: "💧", users_count: 1247 },
      { title: "스트레칭 5분", category: "HEALTH", icon: "🧘", users_count: 982 },
      { title: "종합 영양제 먹기", category: "HEALTH", icon: "💊", users_count: 856 },
      { title: "감사 일기 쓰기", category: "MIND", icon: "✍️", users_count: 734 },
      { title: "책 10페이지 읽기", category: "STUDY", icon: "📚", users_count: 691 },
      { title: "플랭크 1분", category: "HEALTH", icon: "💪", users_count: 623 },
      { title: "명상 5분", category: "MIND", icon: "🧠", users_count: 589 },
      { title: "아침 햇빛 쐬기", category: "HEALTH", icon: "☀️", users_count: 512 },
      { title: "자기 전 폰 안보기", category: "LIFE", icon: "📱", users_count: 487 },
      { title: "하루 목표 3가지 작성", category: "STUDY", icon: "🎯", users_count: 456 },
      { title: "스쿼트 20개", category: "HEALTH", icon: "🏋️", users_count: 423 },
      { title: "영어 단어 10개 외우기", category: "STUDY", icon: "📖", users_count: 398 },
      { title: "사이드 프로젝트 30분", category: "MONEY", icon: "💻", users_count: 367 },
      { title: "블로그 글쓰기", category: "MONEY", icon: "💰", users_count: 334 },
      { title: "운동 30분", category: "HEALTH", icon: "🏃", users_count: 312 }
    ]
  end

  def set_routine
    @routine = current_user.personal_routines.find(params[:id])
  end

  def routine_params
    params.require(:personal_routine).permit(:title, :icon, :color, :category, days: [])
  end
end
