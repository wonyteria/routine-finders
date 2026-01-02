class UserGoal < ApplicationRecord
  belongs_to :user

  enum :goal_type, { short_term: 0, mid_term: 1, long_term: 2 }

  validates :body, presence: true
  validates :goal_type, presence: true
end
