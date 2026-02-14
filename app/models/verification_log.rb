class VerificationLog < ApplicationRecord
  # Enums
  enum :verification_type, { simple: 0, metric: 1, photo: 2, url: 3, complex: 4 }, prefix: true
  enum :status, { pending: 0, approved: 1, rejected: 2 }

  # Associations
  belongs_to :participant
  belongs_to :challenge

  # Validations
  validates :verification_type, presence: true

  # Scopes
  scope :today, -> { where("DATE(created_at) = ?", Date.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_save :update_participant_verification, if: :saved_change_to_status?

  # Methods
  def add_reaction!(reaction_type)
    current_reactions = reactions || []
    existing = current_reactions.find { |r| r["type"] == reaction_type }

    if existing
      existing["count"] += 1
    else
      current_reactions << { "type" => reaction_type, "count" => 1 }
    end

    update(reactions: current_reactions)
  end

  private

  def update_participant_verification
    return unless approved?

    participant.update(
      today_verified: true,
      consecutive_failures: 0,
      completion_rate: calculate_completion_rate
    )
    participant.update_streak!
    BadgeService.new(participant.user).check_and_award_all!
  end

  def calculate_completion_rate
    # 챌린지 전체 기간 기준으로 계산하여 Participant 모델과 로직 통일
    total_days = (challenge.end_date - challenge.start_date).to_i + 1
    total_days = 1 if total_days < 1

    verified_days = participant.verification_logs.approved.select("DISTINCT DATE(created_at)").count
    ((verified_days.to_f / total_days) * 100).round(1)
  end
end
