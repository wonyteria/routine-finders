class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      @user.generate_email_verification_token!
      UserMailer.email_verification(@user).deliver_later

      respond_to do |format|
        format.html { redirect_to root_path, notice: "가입이 완료되었습니다. 이메일을 확인하여 인증을 완료해주세요." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("auth_modal", partial: "shared/registration_success") }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "auth_modal",
            partial: "shared/auth_modal_with_errors",
            locals: { user: @user }
          )
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :nickname)
  end
end
