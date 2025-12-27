class Announcement < ApplicationRecord
  # Associations
  belongs_to :challenge

  # Validations
  validates :title, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
