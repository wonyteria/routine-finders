class CreateMeetingInfos < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_infos do |t|
      t.references :challenge, null: false, foreign_key: true
      t.string :place_name, null: false
      t.string :address
      t.string :meeting_time
      t.text :description
      t.integer :max_attendees, default: 10

      t.timestamps
    end

    # challenge_id 인덱스는 references에서 자동 생성됨, unique 제약만 추가
    remove_index :meeting_infos, :challenge_id
    add_index :meeting_infos, :challenge_id, unique: true
  end
end
