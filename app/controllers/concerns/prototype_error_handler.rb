# frozen_string_literal: true

# 전역 에러 핸들러 - 프로토타입 앱 전용
module PrototypeErrorHandler
  extend ActiveSupport::Concern

  included do
    # 프로덕션 환경에서만 rescue_from 활성화
    unless Rails.env.development?
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    end
  end

  private

  # 404 Not Found
  def handle_not_found(exception)
    Rails.logger.error "Not Found: #{exception.message}"

    if action_name == "home" && controller_name == "prototype"
      render plain: "페이지를 구성하는 일부 데이터를 찾을 수 없습니다. (에러: #{exception.message})", status: :not_found
      return
    end

    respond_to do |format|
      format.html { redirect_to prototype_home_path, alert: "요청하신 페이지를 찾을 수 없습니다." }
      format.json { render json: { error: "Not found" }, status: :not_found }
    end
  end

  # 파라미터 누락
  def handle_parameter_missing(exception)
    Rails.logger.error "Parameter Missing: #{exception.message}"

    if action_name == "home" && controller_name == "prototype"
      render plain: "필수 데이터 요청이 잘못되었습니다. (에러: #{exception.message})", status: :bad_request
      return
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: prototype_home_path, alert: "필수 정보가 누락되었습니다." }
      format.json { render json: { error: exception.message }, status: :bad_request }
    end
  end

  # 레코드 검증 실패
  def handle_record_invalid(exception)
    Rails.logger.error "Record Invalid: #{exception.message}"

    if action_name == "home" && controller_name == "prototype"
      render plain: "데이터 무결성 오류가 발생했습니다. (에러: #{exception.message})", status: :unprocessable_entity
      return
    end

    respond_to do |format|
      format.html { redirect_back fallback_location: prototype_home_path, alert: "입력하신 정보가 올바르지 않습니다." }
      format.json { render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity }
    end
  end

  # 일반 에러
  def handle_standard_error(exception)
    Rails.logger.error "Standard Error: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.first(20).join("\n")

    # 리다이렉트 루프 방지: 현재 페이지가 홈인 경우 리다이렉트하지 않음
    if action_name == "home" && controller_name == "prototype"
      render plain: "시스템 오류가 발생했습니다. 담당자에게 문의해주세요. (에러: #{exception.message})", status: :internal_server_error
      return
    end

    respond_to do |format|
      format.html { redirect_to prototype_home_path, alert: "일시적인 오류가 발생했습니다. (오류: #{exception.message})" }
      format.json { render json: { error: "Internal server error" }, status: :internal_server_error }
    end
  end
end
