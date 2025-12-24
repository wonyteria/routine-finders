module Api
  module V1
    class UsersController < BaseController
      before_action :require_login, except: [:login]

      def me
        render json: current_user.as_json(methods: [:wallet, :participant_stats, :host_stats, :unread_notifications_count])
      end

      def login
        user = User.find_by(email: params[:email])

        if user
          session[:user_id] = user.id
          render json: user.as_json(methods: [:wallet, :participant_stats, :host_stats])
        else
          render json: { error: "사용자를 찾을 수 없습니다." }, status: :not_found
        end
      end

      def logout
        session.delete(:user_id)
        head :no_content
      end

      def participations
        participations = current_user.participations.includes(:challenge)
        render json: participations.as_json(include: :challenge)
      end
    end
  end
end
