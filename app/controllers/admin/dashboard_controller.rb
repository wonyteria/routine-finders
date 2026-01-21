module Admin
  class DashboardController < BaseController
    def index
      begin
        @stats = {
          total_users: User.count,
          new_users_today: User.where(created_at: Time.current.all_day).count,
          active_challenges: Challenge.active.count,
          today_completions: PersonalRoutineCompletion.where(completed_on: Date.current).count,
          total_clubs: RoutineClub.count
        }

        @recent_users = User.order(created_at: :desc).limit(5)
        @recent_challenges = Challenge.order(created_at: :desc).limit(5)
        
        @revenue_data = {
          this_month: 2450000,
          last_month: 1890000,
          growth: 29.6
        }
      rescue => e
        Rails.logger.error "Admin::DashboardController Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    end
  end
end
