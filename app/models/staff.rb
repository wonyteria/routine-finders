class Staff < ApplicationRecord
  # Enums
  enum :staff_role, { operator: 0, feedback: 1, notice: 2 }

  # Associations
  belongs_to :challenge
  belongs_to :user

  # Validations
  validates :nickname, presence: true
end
