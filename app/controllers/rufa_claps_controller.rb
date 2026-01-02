class RufaClapsController < ApplicationController
  before_action :require_login

  def create
    @activity = RufaActivity.find(params[:rufa_activity_id])
    @clap = current_user.rufa_claps.find_or_initialize_by(rufa_activity: @activity)

    if @clap.save
      respond_to do |format|
        format.html { redirect_back fallback_location: personal_routines_path(tab: "club") }
        # Turbo stream for instant update can be added here
        format.turbo_stream
      end
    end
  end
end
