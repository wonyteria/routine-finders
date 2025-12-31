class SessionsController < ApplicationController
  def new
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
    redirect_to root_path, notice: "로그아웃되었습니다."
  end
end
