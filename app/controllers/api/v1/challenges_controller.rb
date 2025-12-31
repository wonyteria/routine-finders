module Api
  module V1
    class ChallengesController < BaseController
      before_action :set_challenge, only: [ :show, :update, :destroy, :join, :leave ]
      before_action :require_login, only: [ :create, :update, :destroy, :join, :leave ]

      def index
        challenges = Challenge.all

        # Filter by mode
        challenges = challenges.where(mode: params[:mode]) if params[:mode].present?

        # Filter by category
        challenges = challenges.where(category: params[:category]) if params[:category].present?

        # Filter by official status
        challenges = challenges.where(is_official: true) if params[:official] == "true"

        challenges = challenges.order(created_at: :desc)

        render json: challenges.as_json(include: :meeting_info)
      end

      def show
        render json: @challenge.as_json(
          include: [ :meeting_info, :staffs ],
          methods: [ :mission_config ]
        )
      end

      def create
        challenge = current_user.hosted_challenges.build(challenge_params)

        if challenge.save
          render json: challenge, status: :created
        else
          render json: { errors: challenge.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @challenge.host_id == current_user.id && @challenge.update(challenge_params)
          render json: @challenge
        else
          render json: { errors: @challenge.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @challenge.host_id == current_user.id
          @challenge.destroy
          head :no_content
        else
          render json: { error: "권한이 없습니다." }, status: :forbidden
        end
      end

      def join
        return render json: { error: "이미 참여 중입니다." }, status: :unprocessable_entity if current_user.participations.exists?(challenge: @challenge)

        participant = @challenge.participants.create!(
          user: current_user,
          paid_amount: @challenge.total_payment_amount,
          joined_at: Time.current
        )

        @challenge.increment!(:current_participants)

        render json: participant, status: :created
      end

      def leave
        participant = current_user.participations.find_by(challenge: @challenge)

        if participant
          participant.destroy
          @challenge.decrement!(:current_participants)
          head :no_content
        else
          render json: { error: "참여 중이 아닙니다." }, status: :not_found
        end
      end

      private

      def set_challenge
        @challenge = Challenge.find(params[:id])
      end

      def challenge_params
        params.require(:challenge).permit(
          :title, :summary, :description, :purpose, :category,
          :start_date, :end_date, :mode, :verification_type, :cost_type,
          :amount, :max_participants, :failure_tolerance,
          :mission_frequency, :mission_is_late_detection_enabled,
          :mission_allow_exceptions, :mission_is_consecutive,
          days: [],
          meeting_info_attributes: [ :place_name, :address, :meeting_time, :description, :max_attendees ]
        )
      end
    end
  end
end
