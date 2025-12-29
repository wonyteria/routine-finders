class PersonalRoutine < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :completions, class_name: "PersonalRoutineCompletion", dependent: :destroy

  # Validations
  validates :title, presence: true

  # Methods
  def completed_today?
    completed_on?(Date.current)
  end

  def completed_on?(date)
    completions.any? { |c| c.completed_on == date }
  end

  def toggle_completion!
    today = Date.current
    completion = completions.find_by(completed_on: today)

    if completion
      # 완료 취소
      completion.destroy
      update_stats!
    else
      # 완료 처리
      completions.create!(completed_on: today)
      update_stats!
    end
  end

  def update_stats!
    # 스트레이크 및 총 완료 횟수 업데이트
    latest_completions = completions.order(completed_on: :desc)

    totalCount = latest_completions.count

    # Calculate streak
    streak = 0
    if latest_completions.any?
      current_date = latest_completions.first.completed_on

      # 만약 마지막 완료일이 오늘이나 어제가 아니면 스트레이크는 0 (또는 오늘 완료했다면 1부터 시작)
      if current_date == Date.current || current_date == Date.yesterday
        streak = 1
        latest_completions.each_cons(2) do |newer, older|
          if newer.completed_on == older.completed_on + 1.day
            streak += 1
          else
            break
          end
        end
      end
    end

    update(
      last_completed_date: latest_completions.first&.completed_on,
      current_streak: streak,
      total_completions: totalCount
    )
  end
end
