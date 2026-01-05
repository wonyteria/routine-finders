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

  def toggle_completion!(date = Date.current)
    completion = completions.find_by(completed_on: date)

    if completion
      # 완료 취소
      completion.destroy
      update_stats!
    else
      # 완료 처리
      completions.create!(completed_on: date)
      update_stats!

      # 루파 클럽 멤버일 경우 활동 피드 생성 (오늘 날짜인 경우에만 생성 권장, 하지만 일단 유연하게 둠)
      # 단, 과거 기록 수정 시 피드가 도배되는 것을 방지하기 위해 오늘인 경우에만 피드 생성 등의 로직 고려 가능.
      # 현재 요구사항은 명확하지 않으므로, 활동 피드는 날짜와 무관하게 생성하되,
      # "과거의 성취를 기록했습니다" 같은 문구 처리는 추후 고려. 일단 유지.
      if user.is_rufa_club_member?
        RufaActivity.create_achievement_activity(user, title)
      end
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
