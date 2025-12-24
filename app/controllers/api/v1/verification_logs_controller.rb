module Api
  module V1
    class VerificationLogsController < BaseController
      before_action :require_login
      before_action :set_challenge
      before_action :set_participant

      def index
        logs = @challenge.verification_logs.recent
        render json: logs
      end

      def create
        log = @participant.verification_logs.build(log_params)
        log.challenge = @challenge

        if log.save
          @participant.update(today_verified: true)
          render json: log, status: :created
        else
          render json: { errors: log.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_challenge
        @challenge = Challenge.find(params[:challenge_id])
      end

      def set_participant
        @participant = current_user.participations.find_by!(challenge: @challenge)
      end

      def log_params
        params.require(:verification_log).permit(:verification_type, :value, :image_url)
      end
    end
  end
end
