class PersonalRoutine < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :title, presence: true

  # Methods
  def completed_today?
    last_completed_date == Date.current
  end

  def toggle_completion!
    today = Date.current

    if last_completed_date == today
      # 완료 취소
      update(
        last_completed_date: nil,
        current_streak: [0, current_streak - 1].max,
        total_completions: [0, total_completions - 1].max
      )
    else
      # 완료 처리
      new_streak = calculate_new_streak
      update(
        last_completed_date: today,
        current_streak: new_streak,
        total_completions: total_completions + 1
      )
    end
  end

  private

  def calculate_new_streak
    if last_completed_date == Date.yesterday
      current_streak + 1
    else
      1
    end
  end
end
