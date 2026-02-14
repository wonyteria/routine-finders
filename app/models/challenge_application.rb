class ChallengeApplication < ApplicationRecord
  # Enums
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  # Associations
  belongs_to :challenge
  belongs_to :user

  # Attributes
  attribute :application_answers, :json, default: -> { {} }

  # Validations
  validates :user_id, uniqueness: { scope: :challenge_id, message: "has already applied to this challenge" }
  validates :depositor_name, presence: true, if: -> { challenge&.cost_type_deposit? || challenge&.cost_type_fee? }
  validates :contact_info, presence: true, if: -> { challenge&.cost_type_deposit? || challenge&.cost_type_fee? }

  validate :answers_presence_validation, if: -> { challenge&.requires_application_message? }

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

  def answers_presence_validation
    if challenge.application_questions.present? && challenge.application_questions.any?
      challenge.application_questions.each do |question|
        if application_answers[question].blank?
          errors.add(:base, "'#{question}' 질문에 답변해주세요.")
        end
      end
    else
      # Fallback to legacy message validation
      if message.blank?
        errors.add(:message, "신청 메시지를 입력해주세요.")
      end
    end
  end

  def set_applied_at
    self.applied_at ||= Time.current
  end
end
