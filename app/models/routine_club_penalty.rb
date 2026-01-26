# frozen_string_literal: true

class RoutineClubPenalty < ApplicationRecord
  belongs_to :routine_club
  belongs_to :routine_club_member
  belongs_to :routine_club_rule, optional: true

  validates :reason, presence: true
end
