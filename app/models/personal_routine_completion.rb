class PersonalRoutineCompletion < ApplicationRecord
  belongs_to :personal_routine

  validates :completed_on, uniqueness: { scope: :personal_routine_id }
end
