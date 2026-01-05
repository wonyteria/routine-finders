module Admin
  class DashboardController < BaseController
    before_action :require_super_admin

    def index
      @stats = {
        total_users: User.count,
        admin_users: User.admin.count,
        verified_users: User.where(email_verified: true).count,
        total_challenges: Challenge.count,
        online_challenges: Challenge.mode_online.count,
        offline_challenges: Challenge.mode_offline.count,
        active_challenges: Challenge.active.count,
        total_personal_routines: PersonalRoutine.count,
        total_participants: Participant.count
      }

      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_challenges = Challenge.order(created_at: :desc).limit(5)

      # Chart Data: User Registration Trend (Last 14 days)
      @user_reg_data = User.where(created_at: 14.days.ago..Time.current)
                           .group("DATE(created_at)")
                           .count
                           .sort.to_h

      # Chart Data: Activity Trend (Verification Logs, Last 14 days)
      @activity_data = VerificationLog.where(created_at: 14.days.ago..Time.current)
                                      .group("DATE(created_at)")
                                      .count
                                      .sort.to_h

      # Fill missing dates for smooth charts
      @dates = (13.days.ago.to_date..Date.current).map { |d| d.to_s }
      @user_reg_values = @dates.map { |d| @user_reg_data[d] || 0 }
      @activity_values = @dates.map { |d| @activity_data[d] || 0 }
    end
  end
end
