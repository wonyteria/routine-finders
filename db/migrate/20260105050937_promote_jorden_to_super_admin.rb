class PromoteJordenToSuperAdmin < ActiveRecord::Migration[8.0]
  def up
    user = User.find_by(email: 'jorden00@naver.com')
    if user
      user.update!(role: :super_admin)
      puts "SUCCESS: User jorden00@naver.com has been promoted to super_admin."
    else
      puts "WARNING: User jorden00@naver.com not found. Migration skipped."
    end
  end

  def down
    # 권한을 이전으로 되돌리고 싶을 경우를 대비 (선택 사항)
    # user = User.find_by(email: 'jorden00@naver.com')
    # user.update!(role: :club_admin) if user
  end
end
