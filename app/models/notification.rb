class Notification < ApplicationRecord
  alias_attribute :message, :content
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
    club_warning: 13,
    club_message: 14,
    challenge_approval: 15,
    challenge_rejection: 16,
    nudge: 17
  }

  # Associations
  belongs_to :user

  # Validations
  validates :title, presence: true
  before_validation :truncate_fields

  private

  def truncate_fields
    self.title = title.to_s.slice(0, 250) if title.present?
  end

  # Scopes
  scope :unread, -> { where(is_read: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Methods
  def mark_as_read!
    update(is_read: true)
  end

  # Push Notification Mapping
  PREFERENCE_MAPPING = {
    announcement: :community,
    approval: :club_status,
    rejection: :club_status,
    application: :club_status,
    badge_award: :achievements,
    club_payment_confirmed: :club_status,
    club_payment_rejected: :club_status,
    club_kicked: :club_operations,
    club_attendance_reminder: :community,
    club_warning: :club_operations,
    club_message: :community,
    challenge_approval: :club_status,
    challenge_rejection: :club_status,
    nudge: :community
  }.freeze

  after_create_commit :send_push_notification

  private

  def send_push_notification
    pref_key = PREFERENCE_MAPPING[notification_type.to_sym]
    return unless pref_key

    if user.notification_enabled?(pref_key)
      WebPushService.send_notification(user, title, content, link || "/")
    end
  rescue => e
    Rails.logger.error "Failed to send push notification for Notification #{id}: #{e.message}"
  end
end
