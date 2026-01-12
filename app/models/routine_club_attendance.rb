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
  def add_cheer(user_id)
    u_id = user_id.to_i
    cheers = get_cheers_list
    unless cheers.include?(u_id)
      cheers << u_id
      self.cheers_from_users = cheers
      self.cheers_count = cheers.count
      save!
    end
  end

  def remove_cheer(user_id)
    u_id = user_id.to_i
    cheers = get_cheers_list
    if cheers.include?(u_id)
      cheers.delete(u_id)
      self.cheers_from_users = cheers
      self.cheers_count = cheers.count
      save!
    end
  end

  def cheered_by?(user_id)
    get_cheers_list.include?(user_id.to_i)
  end

  private

  def get_cheers_list
    list = cheers_from_users
    if list.is_a?(String)
      begin
        list = JSON.parse(list)
      rescue JSON::ParserError
        list = []
      end
    end
    Array(list).map(&:to_i).uniq.compact
  end
end
