class EmailVerificationsController < ApplicationController
  def show
    user = User.find_by(email_verification_token: params[:token])

    if user.nil?
      redirect_to root_path, alert: "유효하지 않은 인증 링크입니다."
    elsif !user.email_verification_token_valid?
      redirect_to root_path, alert: "인증 링크가 만료되었습니다. 다시 인증 메일을 요청해주세요."
    else
      user.verify_email!
      session[:user_id] = user.id
      redirect_back_or root_path
      flash[:notice] = "이메일 인증이 완료되었습니다. 환영합니다!"
    end
  end

  def resend
    user = User.find_by(email: params[:email])

    # Rate limiting: 1분 이내 재발송 방지
    if user && !user.email_verified?
      if user.email_verification_sent_at && user.email_verification_sent_at > 1.minute.ago
        redirect_to root_path, alert: "잠시 후 다시 시도해주세요."
        return
      end

      user.generate_email_verification_token!
      UserMailer.email_verification(user).deliver_later
      redirect_to root_path, notice: "인증 메일을 다시 발송했습니다."
    else
      # 보안: 사용자 존재 여부를 노출하지 않음
      redirect_to root_path, notice: "해당 이메일로 가입된 미인증 계정이 있다면 인증 메일이 발송됩니다."
    end
  end
end
