class Participant < ApplicationRecord
  # Enums
  enum :status, { achieving: 0, lagging: 1, inactive: 2, failed: 3 }
  attribute :refund_status, :integer, default: 0
  enum :refund_status, { refund_none: 0, refund_applied: 1, refund_completed: 2 }

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
      max_streak: [ max_streak, streak ].max,
      consecutive_failures: 0 # Reset consecutive failures on success
    )
    check_status!
  end

  def record_failure!
    update(
      consecutive_failures: consecutive_failures + 1,
      total_failures: total_failures + 1
    )
    check_status!
  end

  def failed?
    status == "failed"
  end

  def status_badge_info
    case status.to_sym
    when :achieving
      { label: "🔥 달성 중", class: "bg-orange-50 text-orange-600 border-orange-100" }
    when :lagging
      { label: "⚠️ 부진", class: "bg-amber-50 text-amber-600 border-amber-100" }
    when :inactive
      { label: "❌ 미참여", class: "bg-slate-50 text-slate-400 border-slate-100" }
    when :failed
      { label: "☠️ 탈락", class: "bg-red-50 text-red-600 border-red-100" }
    else
      { label: "알 수 없음", class: "bg-slate-50 text-slate-400 border-slate-100" }
    end
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
    if total_failures >= challenge.failure_tolerance
      update(status: :failed)
    elsif consecutive_failures >= (challenge.non_participating_failures_threshold || 5) || completion_rate < (challenge.sluggish_rate_threshold || 0.4)
      update(status: :inactive)
    elsif consecutive_failures > 0 || completion_rate < (challenge.active_rate_threshold || 0.8)
      update(status: :lagging)
    else
      update(status: :achieving)
    end
  end
end
