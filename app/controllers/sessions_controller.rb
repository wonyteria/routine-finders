class SessionsController < ApplicationController
  def create
    # 간단한 데모 로그인 - 실제로는 인증 시스템 사용
    user = User.find_by(email: "routine@example.com")
    if user
      session[:user_id] = user.id
      redirect_to root_path, notice: "로그인되었습니다!"
    else
      redirect_to root_path, alert: "로그인에 실패했습니다."
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "로그아웃되었습니다."
  end
end
