class RoutineClubReportsController < ApplicationController
  before_action :require_login
  before_action :require_rufa_club_member
  before_action :set_report, only: [ :show ]

  def index
    @reports = current_user.routine_club_reports.order(start_date: :desc)
  end

  def show
    # @report is set by set_report
  end

  # 개발/테스트용: 현재 유저의 이번 달 리포트 즉시 생성
  def generate_current
    membership = current_user.routine_club_members.active.confirmed.first
    if membership
      # 전월 데이터가 없을 수 있으므로 이번 달 데이터를 기반으로 생성 (테스트용)
      start_date = Date.current.beginning_of_month
      end_date = Date.current.end_of_month

      # 기존 리포트 삭제 후 재생성 (테스트 목적)
      current_user.routine_club_reports.where(start_date: start_date).destroy_all

      RoutineClubReportService.send(:create_report, membership, :monthly, start_date, end_date)
      redirect_to routine_club_report_path(current_user.routine_club_reports.last), notice: "이번 달 루파 리포트가 생성되었습니다!"
    else
      redirect_to personal_routines_path, alert: "루파 클럽 멤버만 리포트를 생성할 수 있습니다."
    end
  end

  private

  def set_report
    @report = current_user.routine_club_reports.find(params[:id])
  end
end
