class HomeController < ApplicationController
  def index
    @current_user = current_user
    @online_challenges = Challenge.online_challenges.order(created_at: :desc).limit(10)
    @offline_gatherings = Challenge.offline_gatherings.order(created_at: :desc).limit(10)
    @personal_routines = @current_user&.personal_routines || []
    @participations = @current_user&.participations&.includes(:challenge) || []
    @verification_logs = @current_user ? VerificationLog.joins(participant: :user).where(users: { id: @current_user.id }).recent.limit(365) : []
  end
end
