# frozen_string_literal: true

class RoutineClubRule < ApplicationRecord
  # Enums
  enum :rule_type, { attendance: 0, behavior: 1, communication: 2, custom: 3 }, prefix: true

  # Associations
  belongs_to :routine_club

  # Validations
  validates :title, presence: true

  # Scopes
  scope :ordered, -> { order(:position) }
end
