class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :omniauth

  def new
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    Rails.logger.info "Starting OmniAuth for provider: #{auth.provider}, uid: #{auth.uid}"

    user = User.from_omniauth(auth)

    if user.persisted?
      session[:user_id] = user.id
      redirect_to root_path, notice: "#{auth.provider.to_s.titleize} 계정으로 로그인되었습니다!"
    else
      error_msg = user.errors.full_messages.to_sentence
      Rails.logger.error "OmniAuth login failed for #{auth.provider}: #{error_msg}"
      redirect_to root_path, alert: "로그인에 실패했습니다: #{error_msg}"
    end
  rescue => e
    Rails.logger.error "OmniAuth Critical Error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to root_path, alert: "로그인 과정에서 시스템 오류가 발생했습니다. 잠시 후 다시 시도해 주세요."
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.authenticate(params[:password])
      if user.email_verified?
        session[:user_id] = user.id
        redirect_back_or root_path
        flash[:notice] = "로그인되었습니다!"
      else
        respond_to do |format|
          format.html { redirect_to root_path, alert: "이메일 인증을 완료해주세요." }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "auth_modal",
              partial: "shared/verification_required",
              locals: { email: user.email }
            )
          end
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to root_path, alert: "이메일 또는 비밀번호가 올바르지 않습니다." }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "login_error",
            "<p class='text-red-500 text-sm'>이메일 또는 비밀번호가 올바르지 않습니다.</p>"
          )
        end
      end
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "로그아웃되었습니다.", status: :see_other
  end
end
