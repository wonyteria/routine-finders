class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @participations = @user.participations.includes(:challenge)
  end
end
