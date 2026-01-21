module Admin
  class DashboardController < BaseController
    def index
      begin
        # Core Statistics
        @stats = {
          total_users: User.active.count,
          new_users_today: User.where(created_at: Time.current.all_day).count,
          active_challenges: Challenge.active.count,
          today_completions: PersonalRoutineCompletion.where(completed_on: Date.current).count,
          total_clubs: RoutineClub.count
        }

        # Action Center (What needs admin attention)
        @action_items = {
          pending_payments: RoutineClubMember.payment_status_pending.count,
          pending_verifications: VerificationLog.pending.count,
          low_stock_prizes: 0 # Placeholder for future gifticon management
        }

        # Activity Monitoring
        @active_users_today = User.joins("LEFT JOIN personal_routine_completions ON personal_routine_completions.user_id = users.id")
                                 .joins("LEFT JOIN rufa_activities ON rufa_activities.user_id = users.id")
                                 .where("personal_routine_completions.completed_on = ? OR DATE(rufa_activities.created_at) = ?", Date.current, Date.current)
                                 .distinct.count

        @recent_users = User.order(created_at: :desc).limit(8)
        @recent_activities = RufaActivity.includes(:user).order(created_at: :desc).limit(10)
        
        # Financial Overview
        @revenue_data = {
          this_month: RoutineClubMember.payment_status_confirmed.where(deposit_confirmed_at: Time.current.all_month).sum(:paid_amount),
          last_month: RoutineClubMember.payment_status_confirmed.where(deposit_confirmed_at: 1.month.ago.all_month).sum(:paid_amount),
          total_revenue: RoutineClubMember.payment_status_confirmed.sum(:paid_amount)
        }
        
        @revenue_data[:growth] = if @revenue_data[:last_month] > 0
          ((@revenue_data[:this_month].to_f - @revenue_data[:last_month]) / @revenue_data[:last_month] * 100).round(1)
        else
          100.0
        end

      rescue => e
        Rails.logger.error "Admin::DashboardController Error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        @error = e.message
      end
    end
  end
end
