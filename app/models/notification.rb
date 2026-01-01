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
    application: 7,
    badge_award: 8,
    club_payment_confirmed: 9,
    club_payment_rejected: 10,
    club_kicked: 11,
    club_attendance_reminder: 12,
    club_warning: 13
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
