module Api
  module V1
    class BaseController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :set_default_format

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      private

      def set_default_format
        request.format = :json
      end

      def current_user
        @_current_user ||= session[:user_id] ? User.find_by(id: session[:user_id]) : nil
      end

      def require_login
        render json: { error: "로그인이 필요합니다." }, status: :unauthorized unless current_user
      end

      def not_found
        render json: { error: "리소스를 찾을 수 없습니다." }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
