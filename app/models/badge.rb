class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :name, presence: true
  validates :badge_type, presence: true
  validates :level, presence: true
  validates :requirement_value, presence: true

  enum :badge_type, { achievement_rate: "achievement_rate", verification_count: "verification_count", max_streak: "max_streak" }
  enum :level, { bronze: 1, silver: 2, gold: 3, platinum: 4, diamond: 5 }
end
