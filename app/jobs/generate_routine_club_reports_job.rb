class GenerateRoutineClubReportsJob < ApplicationJob
  queue_as :default

  def perform(type)
    case type.to_sym
    when :weekly
      RoutineClubReportService.generate_weekly_reports
    when :monthly
      RoutineClubReportService.generate_monthly_reports
    end
  end
end
