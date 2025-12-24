class UserMailer < ApplicationMailer
  def email_verification(user)
    @user = user
    @verification_url = verify_email_url(token: user.email_verification_token)

    mail(
      to: user.email,
      subject: "[루틴파인더스] 이메일 인증을 완료해주세요"
    )
  end
end
