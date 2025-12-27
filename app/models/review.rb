class Review < ApplicationRecord
  # Associations
  belongs_to :challenge
  belongs_to :user

  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :challenge_id, message: "has already reviewed this challenge" }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :top_rated, -> { order(rating: :desc) }

  # Callbacks
  after_save :update_challenge_average_rating
  after_destroy :update_challenge_average_rating

  private

  def update_challenge_average_rating
    avg = challenge.reviews.average(:rating) || 0
    challenge.update_column(:average_rating, avg.round(2))
  end
end
