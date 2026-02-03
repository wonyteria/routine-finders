# frozen_string_literal: true

class RoutineClubAttendance < ApplicationRecord
  # Enums
  enum :status, { present: 0, absent: 1, excused: 2 }, prefix: true

  # Associations
  belongs_to :routine_club
  belongs_to :routine_club_member

  # Validations
  validates :attendance_date, presence: true
  validates :routine_club_member_id, uniqueness: { scope: :attendance_date }

  # Scopes
  scope :today, -> { where(attendance_date: Date.current) }
  scope :this_week, -> { where(attendance_date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
end
