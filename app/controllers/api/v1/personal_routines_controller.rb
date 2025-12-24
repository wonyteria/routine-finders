module Api
  module V1
    class PersonalRoutinesController < BaseController
      before_action :require_login
      before_action :set_routine, only: [:show, :update, :destroy, :toggle]

      def index
        routines = current_user.personal_routines.order(created_at: :desc)
        render json: routines
      end

      def show
        render json: @routine
      end

      def create
        routine = current_user.personal_routines.build(routine_params)

        if routine.save
          render json: routine, status: :created
        else
          render json: { errors: routine.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @routine.update(routine_params)
          render json: @routine
        else
          render json: { errors: @routine.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @routine.destroy
        head :no_content
      end

      def toggle
        @routine.toggle_completion!
        render json: @routine
      end

      private

      def set_routine
        @routine = current_user.personal_routines.find(params[:id])
      end

      def routine_params
        params.require(:personal_routine).permit(:title, :icon, :color, :category, days: [])
      end
    end
  end
end
