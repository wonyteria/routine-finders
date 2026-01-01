# frozen_string_literal: true

class RoutineClubReport < ApplicationRecord
  # Enums
  enum :report_type, { weekly: 0, monthly: 1 }, prefix: true

  # Associations
  belongs_to :routine_club
  belongs_to :user

  # Validations
  validates :start_date, presence: true
  validates :end_date, presence: true
end
