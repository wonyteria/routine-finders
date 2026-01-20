class RufaActivity < ApplicationRecord
  belongs_to :user
  has_many :claps, class_name: "RufaClap", dependent: :destroy

  validates :activity_type, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def self.create_goal_activity(user, goal)
    create!(
      user: user,
      activity_type: "goal_update",
      target_id: goal.id,
      target_type: "UserGoal",
      body: "새로운 성취 목표를 선언했습니다: #{goal.body}"
    )
  end

  def self.create_achievement_activity(user, title)
    create!(
      user: user,
      activity_type: "routine_achievement",
      body: "오늘의 루틴 '#{title}'을(를) 완수하며 성장했습니다!"
    )
  end

  def self.create_reflection_activity(user, body)
    create!(
      user: user,
      activity_type: "reflection",
      body: body
    )
  end
end
