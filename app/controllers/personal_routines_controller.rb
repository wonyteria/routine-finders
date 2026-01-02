class PersonalRoutinesController < ApplicationController
  before_action :require_login
  before_action :set_routine, only: [ :edit, :update, :toggle, :destroy ]

  def index
    return redirect_to login_path unless logged_in?

    # 개인 루틴 (무료)
    current_user.user_badges.where(is_viewed: false).update_all(is_viewed: true)

    @personal_routines = current_user.personal_routines.includes(:completions).order(created_at: :desc)
    @monthly_completions = current_user.personal_routines.joins(:completions)
                                       .where(personal_routine_completions: { completed_on: Date.current.beginning_of_month..Date.current.end_of_month })

    # 루파 클럽 공식 생성 (없을 경우)
    @official_club = RoutineClub.official.first
    unless @official_club
      admin = User.find_by(role: :admin) || User.first
      @official_club = RoutineClub.create!(
        title: "루파 클럽 공식",
        description: "루틴 파인더스가 직접 운영하는 단 하나의 공식 루파 클럽입니다. 압도적 성장을 위한 최적의 시스템!",
        monthly_fee: 5000,
        min_duration_months: 3,
        start_date: Date.current,
        end_date: Date.current + 1.year,
        is_official: true,
        host: admin,
        category: "건강·운동"
      )
    end

    # 루파 클럽 (유료) 관련 통계 및 랭킹
    @routine_clubs = RoutineClub.recruiting_clubs.includes(:host, :members).order(created_at: :desc).limit(6)
    @my_club_memberships = current_user.routine_club_members.includes(:routine_club).where(status: [ :active, :warned ])
    @my_club_memberships.each do |m|
      if m.identity_title.blank?
        m.update(identity_title: "시작하는 파인더 (Beginning Finder)")
      end
    end
    @pending_payments = current_user.routine_club_members.where(payment_status: :pending)

    # 루파 클럽 공식 공지사항
    if @official_club && Announcement.where(routine_club: @official_club).none?
      @official_club.announcements.create!(title: "루파 클럽에 오신 것을 환영합니다! 목표 설정을 시작해보세요.", content: "내용")
      @official_club.announcements.create!(title: "1월 오프라인 정기 모임 일정 안내", content: "내용")
    end
    @rufa_announcements = @official_club ? Announcement.where(routine_club: @official_club).recent.limit(5) : []

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

    # 루파 통계 (요약)
    @current_log_rate = current_user.monthly_routine_log_rate
    @current_achievement_rate = current_user.monthly_achievement_rate

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

    @recommended_routines = [
      { title: "종합 영양제 먹기", category: "HEALTH", icon: "💊", color: "text-rose-400" },
      { title: "물 2L 마시기", category: "HEALTH", icon: "💧", color: "text-blue-400" },
      { title: "스트레칭 5분", category: "HEALTH", icon: "🧘", color: "text-emerald-400" },
      { title: "안약 넣기", category: "LIFE", icon: "👀", color: "text-sky-400" },
      { title: "책상 정리하기", category: "PRODUCTIVITY", icon: "🧹", color: "text-orange-400" },
      { title: "내일 할 일 계획", category: "PRODUCTIVITY", icon: "📝", color: "text-purple-400" },
      { title: "스킨케어 루틴", category: "LIFE", icon: "✨", color: "text-pink-400" },
      { title: "감사 일기 쓰기", category: "MIND", icon: "✍️", color: "text-yellow-400" },
      { title: "자기 전 폰 안보기", category: "LIFE", icon: "📱", color: "text-indigo-400" },
      { title: "스쿼트 20개", category: "HEALTH", icon: "🏋️", color: "text-orange-500" }
    ]

    # 루파 성장 레이더용 카테고리별 통계
    @category_stats = current_user.personal_routines.joins(:completions)
                                  .where(personal_routine_completions: { completed_on: Date.current.beginning_of_month..Date.current.end_of_month })
                                  .group(:category).count
    # 기본 카테고리 보정 (데이터가 없을 경우 0)
    @rufa_categories = [ "HEALTH", "LIFE", "MIND", "STUDY", "HOBBY" ]
    @rufa_categories.each { |cat| @category_stats[cat] ||= 0 }

    # 점수 트렌드 (최근 7일간의 달성률 변화)
    @achievement_trend = (0..6).map do |i|
      date = i.days.ago.to_date
      completions = current_user.personal_routines.joins(:completions).where(personal_routine_completions: { completed_on: date }).count
      total = current_user.personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }.count
      total > 0 ? (completions.to_f / total * 100).round : 0
    end.reverse
  end

  def create
    @routine = current_user.personal_routines.build(routine_params)

    if @routine.save
      respond_to do |format|
        format.html { redirect_to personal_routines_path, notice: "루틴이 추가되었습니다!" }
        format.turbo_stream
      end
    else
      redirect_to personal_routines_path, alert: "루틴 추가에 실패했습니다."
    end
  end

  def edit
  end

  def update
    if @routine.update(routine_params)
      respond_to do |format|
        format.html { redirect_to personal_routines_path, notice: "루틴이 수정되었습니다!" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle
    @routine.toggle_completion!

    respond_to do |format|
      format.html { redirect_to personal_routines_path }
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
    @routine.destroy

    respond_to do |format|
      format.html { redirect_to personal_routines_path, notice: "루틴이 삭제되었습니다." }
      format.turbo_stream
    end
  end

  private

  def set_routine
    @routine = current_user.personal_routines.find(params[:id])
  end

  def routine_params
    params.require(:personal_routine).permit(:title, :icon, :color, :category, days: [])
  end
end
