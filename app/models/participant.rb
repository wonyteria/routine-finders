class Participant < ApplicationRecord
  # Enums
  enum :status, { achieving: 0, lagging: 1, inactive: 2, failed: 3 }

  # Associations
  belongs_to :user
  belongs_to :challenge
  has_many :verification_logs, dependent: :destroy

  # Validations
  validates :user_id, uniqueness: { scope: :challenge_id, message: "is already participating in this challenge" }
  validates :joined_at, presence: true

  # Callbacks
  before_validation :set_defaults, on: :create
  before_save :sync_user_info

  # Methods
  def update_streak!
    logs = verification_logs.order(created_at: :desc)
    return if logs.empty?

    streak = 0
    logs.each do |log|
      break unless log.approved?
      streak += 1
    end

    update(
      current_streak: streak,
      max_streak: [ max_streak, streak ].max
    )
  end

  def record_failure!
    update(
      consecutive_failures: consecutive_failures + 1,
      total_failures: total_failures + 1
    )
    check_status!
  end

  private

  def set_defaults
    self.joined_at ||= Time.current
    self.nickname ||= user&.nickname
    self.profile_image ||= user&.profile_image
  end

  def sync_user_info
    self.nickname ||= user&.nickname
    self.profile_image ||= user&.profile_image
  end

  def check_status!
    if consecutive_failures >= challenge.failure_tolerance
      update(status: :failed)
    elsif consecutive_failures >= 2
      update(status: :lagging)
    end
  end
end
