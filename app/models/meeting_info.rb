class MeetingInfo < ApplicationRecord
  # Associations
  belongs_to :challenge

  # Validations
  validates :place_name, presence: true
  validates :challenge_id, uniqueness: true
end
