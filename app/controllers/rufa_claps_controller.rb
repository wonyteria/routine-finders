class RufaClapsController < ApplicationController
  before_action :require_login

  def create
    @activity = RufaActivity.find(params[:rufa_activity_id])
    @clap = current_user.rufa_claps.find_by(rufa_activity: @activity)

    if @clap
      @clap.destroy
      clapped = false
    else
      current_user.rufa_claps.create(rufa_activity: @activity)
      # 배지 체크 (박수 횟수 배지)
      BadgeService.new(current_user).check_and_award_all!
      clapped = true
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: personal_routines_path(tab: "club") }
      format.json { render json: { success: true, clapped: clapped, claps_count: @activity.reload.claps_count } }
      format.turbo_stream
    end
  end
end
