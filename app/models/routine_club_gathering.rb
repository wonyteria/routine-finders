class RoutineClubGathering < ApplicationRecord
  belongs_to :routine_club

  enum :gathering_type, { online: 0, offline: 1 }

  validates :title, presence: true
  validates :gathering_at, presence: true
end
