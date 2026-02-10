class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :omniauth, :dev_login ]

  def new
  end

  # 개발 환경 전용 자동 로그인
  def dev_login
    unless Rails.env.development?
      redirect_to prototype_home_path, alert: "이 기능은 개발 환경에서만 사용할 수 있습니다."
      return
    end

    # 테스트 사용자 찾거나 생성
    user = User.find_or_create_by!(email: "test@example.com") do |u|
      u.name = "테스트 사용자"
      u.provider = "developer"
      u.uid = "test_user_#{SecureRandom.hex(4)}"
    end

    session[:user_id] = user.id
    redirect_back_or prototype_home_path
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    unless auth
      Rails.logger.error "OmniAuth: Request environment 'omniauth.auth' is nil"
      redirect_to prototype_home_path, alert: "인증 정보를 가져오지 못했습니다. 다시 시도해 주세요."
      return
    end

    Rails.logger.info "Starting OmniAuth for provider: #{auth.provider}, uid: #{auth.uid}"

    user = User.from_omniauth(auth)

    # Check if the user account was deleted
    if user&.deleted?
      # Store user info in session for restoration flow
      session[:deleted_user_id] = user.id
      session[:auth_provider] = auth.provider
      redirect_to restore_account_path, notice: "이전에 탈퇴한 계정이 있습니다."
      return
    end

    if user&.persisted?
      # Check if this is a new user (onboarding not completed)
      is_new_user = user.respond_to?(:onboarding_completed?) && !user.onboarding_completed?

      session[:user_id] = user.id

      if is_new_user
        flash[:show_onboarding] = true
      else
        flash[:show_daily_greeting] = true
      end

      redirect_back_or prototype_home_path
    else
      error_msg = user ? user.errors.full_messages.to_sentence : "사용자를 생성하거나 찾을 수 없습니다."
      Rails.logger.error "OmniAuth login failed for #{auth.provider}: #{error_msg}"
      redirect_to prototype_home_path, alert: "로그인에 실패했습니다: #{error_msg}"
    end
  rescue => e
    Rails.logger.error "OmniAuth Critical Error: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}"
    redirect_to prototype_home_path, alert: "로그인 과정에서 시스템 오류가 발생했습니다: #{e.message}. 잠시 후 다시 시도해 주세요."
  end

  def omniauth_failure
    message = params[:message]
    strategy = params[:strategy]

    error_type = if message.to_s.include?("InvalidAuthenticityToken") || message.to_s.include?("csrf_detected")
      "session_expired_or_csrf_error"
    else
      message
    end

    Rails.logger.error "OmniAuth Failure Action: strategy=#{strategy}, message=#{message}"

    redirect_to "/?auth_error=#{error_type}&strategy=#{strategy}"
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_back_or prototype_home_path
      flash[:notice] = "로그인되었습니다!"
    else
      respond_to do |format|
        format.html { redirect_to prototype_home_path, alert: "이메일 또는 비밀번호가 올바르지 않습니다." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "login_error",
            "<p class='text-red-500 text-sm'>이메일 또는 비밀번호가 올바르지 않습니다.</p>"
          )
        end
      end
    end
  end

  def restore_account
    @user = User.find_by(id: session[:deleted_user_id])
    unless @user&.deleted?
      redirect_to prototype_home_path, alert: "복구할 계정을 찾을 수 없습니다."
    end
  end

  def confirm_restore
    user = User.find_by(id: session[:deleted_user_id])

    if user&.deleted?
      user.restore
      session[:user_id] = user.id
      session.delete(:deleted_user_id)
      session.delete(:auth_provider)
      redirect_back_or prototype_home_path
      flash[:notice] = "계정이 복구되었습니다. 다시 오신 것을 환영합니다!"
    else
      redirect_to prototype_home_path, alert: "계정 복구에 실패했습니다."
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "로그아웃되었습니다.", status: :see_other
  end

  def complete_onboarding
    if current_user && current_user.respond_to?(:onboarding_completed=)
      current_user.update(onboarding_completed: true)
      head :ok
    else
      head :unauthorized
    end
  end
end
