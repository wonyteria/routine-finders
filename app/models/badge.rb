# frozen_string_literal: true

class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :name, presence: true
  validates :badge_type, presence: true
  validates :level, presence: true
  validates :requirement_value, presence: true


  enum :badge_type, {
    achievement_rate: "achievement_rate",
    verification_count: "verification_count",
    max_streak: "max_streak",
    participation_count: "participation_count",
    host_participants: "host_participants",
    host_completion: "host_completion",
    host_count: "host_count",
    club_membership: "club_membership",
    club_session_count: "club_session_count",
    club_attendance_perfect: "club_attendance_perfect",
    club_moderator: "club_moderator",
    club_rank_top_1: "club_rank_top_1",
    club_rank_top_3: "club_rank_top_3",
    club_rank_top_10: "club_rank_top_10",
    club_share_count: "club_share_count",
    cheer_count: "cheer_count"
  }
  enum :level, { bronze: 1, silver: 2, gold: 3, platinum: 4, diamond: 5, master: 6, legend: 7, mythic: 8 }
  enum :target_type, { all: "all", challenge: "challenge", routine: "routine", gathering: "gathering", host: "host", club: "club" }, prefix: true
end
