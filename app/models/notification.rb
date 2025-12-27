class Notification < ApplicationRecord
  # Enums
  enum :notification_type, {
    reminder: 0,
    deadline: 1,
    announcement: 2,
    approval: 3,
    rejection: 4,
    settlement: 5,
    system: 6,
    application: 7
  }

  # Associations
  belongs_to :user

  # Validations
  validates :title, presence: true

  # Scopes
  scope :unread, -> { where(is_read: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def mark_as_read!
    update(is_read: true)
  end
end
