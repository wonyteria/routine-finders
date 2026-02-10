class ClubPerformanceCheckJob < ApplicationJob
  queue_as :default

  def perform
    official_club = RoutineClub.official.first
    if official_club
      Rails.logger.info "Starting weekly performance check for #{official_club.title}"
      results = official_club.check_all_members_weekly_performance!
      Rails.logger.info "Performance check completed: #{results.inspect}"
    else
      Rails.logger.error "Official club not found. Skipping performance check."
    end
  end
end
