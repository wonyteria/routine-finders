class FixAnnouncementsForeignKeyConstraints < ActiveRecord::Migration[8.1]
  def up
    # challenge_id와 routine_club_id를 모두 nullable로 변경
    # 하나는 반드시 있어야 하지만, 둘 다 필수는 아님
    change_column_null :announcements, :challenge_id, true

    # routine_club_id 컬럼이 존재하는 경우에만 nullable로 변경
    if column_exists?(:announcements, :routine_club_id)
      change_column_null :announcements, :routine_club_id, true
    end
  end

  def down
    # 롤백 시에는 아무것도 하지 않음 (데이터 손실 방지)
    # 필요하다면 수동으로 제약조건을 다시 추가해야 함
  end
end
