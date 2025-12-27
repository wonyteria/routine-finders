class ChallengeApplication < ApplicationRecord
  # Enums
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  # Associations
  belongs_to :challenge
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :challenge_id, message: "has already applied to this challenge" }
  validates :depositor_name, presence: true, if: -> { challenge&.cost_type_deposit? || challenge&.cost_type_fee? }
  validates :message, presence: true, if: -> { challenge&.requires_application_message? }

  # Callbacks
  before_create :set_applied_at

  # Scopes
  scope :recent, -> { order(applied_at: :desc) }

  def approve!
    update!(status: :approved)
  end

  def reject!(reason = nil)
    update!(status: :rejected, reject_reason: reason)
  end

  private

  def set_applied_at
    self.applied_at ||= Time.current
  end
end
