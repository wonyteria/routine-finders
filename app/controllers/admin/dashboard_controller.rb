module Admin
  class DashboardController < BaseController
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
    end
  end
end
