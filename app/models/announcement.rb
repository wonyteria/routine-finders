class Announcement < ApplicationRecord
  # Associations
  belongs_to :challenge, optional: true
  belongs_to :routine_club, optional: true

  # Validations
  validates :title, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
