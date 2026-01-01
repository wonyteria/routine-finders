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
  scope :recent, -> { order(attendance_date: :desc) }

  # Methods
  def add_cheer(user_id)
    cheers = cheers_from_users || []
    unless cheers.include?(user_id)
      cheers << user_id
      update(cheers_from_users: cheers, cheers_count: cheers.count)
    end
  end

  def remove_cheer(user_id)
    cheers = cheers_from_users || []
    if cheers.include?(user_id)
      cheers.delete(user_id)
      update(cheers_from_users: cheers, cheers_count: cheers.count)
    end
  end

  def cheered_by?(user_id)
    (cheers_from_users || []).include?(user_id)
  end
end
